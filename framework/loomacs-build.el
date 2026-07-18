;;; loomacs-build.el --- Loomacs 可回滚显式构建 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW
;; URL: https://github.com/auspicious-ssw/loomacs
;; Package-Requires: ((emacs "30.2"))

;;; Commentary:

;; 构建流程：config.org -> staging Manifest -> 模块 Org -> staging Elisp ->
;; 结构与读取校验 -> 替换 generated -> 创建并激活 Release。任何预发布失败都
;; 保留旧 generated；发布阶段失败会恢复备份。

;;; Code:

(require 'pp)
(require 'loomacs-release)
(require 'loomacs-tangle)

(define-error 'loomacs-build-error "Loomacs 构建失败")

(defun loomacs-build-lock-directory ()
  "返回显式构建互斥锁目录。"
  (expand-file-name ".loomacs-build.lock" loomacs-root-directory))

(defun loomacs-build--acquire-lock ()
  "取得构建锁；已有构建或遗留锁时明确失败。"
  (let ((lock (loomacs-build-lock-directory))
        created)
    (condition-case error-data
        (progn
          (make-directory lock)
          (setq created t)
          (with-temp-file (expand-file-name "owner.el" lock)
            (prin1 `(:pid ,(emacs-pid)
                     :started-at ,(format-time-string "%Y-%m-%dT%H:%M:%S%z"))
                   (current-buffer))
            (insert "\n"))
          lock)
      (file-already-exists
       (signal 'loomacs-build-error
               (list (format "已有构建锁 %s；确认没有构建进程后再删除遗留锁"
                             lock))))
      (error
       (when (and created (file-directory-p lock))
         (ignore-errors (delete-directory lock t)))
       (signal 'loomacs-build-error
               (list (format "无法取得构建锁：%s"
                             (error-message-string error-data))))))))

(defun loomacs-build--release-lock (lock)
  "删除当前构建创建的 LOCK。"
  (when (and lock (file-directory-p lock))
    (condition-case error-data
        (delete-directory lock t)
      (error
       (loomacs-log 'warning "构建锁未能清理：%s"
                    (error-message-string error-data))))))

(defun loomacs-build--write-metadata (manifest destination)
  "将 MANIFEST 的确定性源码与生成物摘要写入 DESTINATION。"
  (let ((sources (cons "config.org"
                       (mapcar (lambda (module) (plist-get module :source))
                               (loomacs-manifest-modules manifest))))
        (outputs (cons "loomacs-manifest.el"
                       (mapcar (lambda (module) (plist-get module :output))
                               (loomacs-manifest-modules manifest))))
        source-digests
        output-digests)
    (dolist (relative (delete-dups sources))
      (let ((source (loomacs-expand-safe-path relative loomacs-root-directory)))
        (push (cons relative (loomacs-file-sha256 source)) source-digests)))
    (dolist (relative (delete-dups outputs))
      (let ((output (loomacs-expand-safe-path relative destination)))
        (unless (file-readable-p output)
          (signal 'loomacs-build-error
                  (list (format "生成物摘要目标不可读：%s" output))))
        (push (cons relative (loomacs-file-sha256 output)) output-digests)))
    (setq source-digests (nreverse source-digests)
          output-digests (nreverse output-digests))
    (let ((file (expand-file-name "loomacs-build-metadata.el" destination)))
      (with-temp-file file
        (insert ";;; loomacs-build-metadata.el --- 自动生成，请勿手改 -*- lexical-binding: t; -*-\n\n")
        (insert ";; 该文件保存确定性源码与生成物摘要；它自身不参与自哈希。\n")
        (insert ";; 构建时间属于本机 Release 元数据，不写入 Git 生成物，避免无语义 diff。\n\n")
        (insert "(setq loomacs-build-metadata\n      '")
        (pp `(:format 1
              :framework-version ,loomacs-version
              :sources ,source-digests
              :outputs ,output-digests)
            (current-buffer))
        (insert ")\n\n(provide 'loomacs-build-metadata)\n")
        (insert ";;; loomacs-build-metadata.el ends here\n"))
      file)))

(defun loomacs-build--validate-staging (manifest staging-generated)
  "对 STAGING-GENERATED 中的 MANIFEST 和模块做完整静态校验。"
  (loomacs-manifest-validate manifest loomacs-root-directory staging-generated)
  (let ((metadata (expand-file-name "loomacs-build-metadata.el"
                                    staging-generated)))
    (unless (file-readable-p metadata)
      (signal 'loomacs-build-error (list "构建元数据未生成")))
    (loomacs-module-read-file metadata))
  t)

(defun loomacs-build--replace-generated (staging-generated target)
  "用已验证 STAGING-GENERATED 替换 TARGET，返回旧目录备份或 nil。"
  (unless (file-directory-p staging-generated)
    (signal 'loomacs-build-error
            (list (format "staging generated 不是目录：%s" staging-generated))))
  (when (and (or (file-exists-p target) (file-symlink-p target))
             (or (not (file-directory-p target)) (file-symlink-p target)))
    (signal 'loomacs-build-error
            (list (format "拒绝覆盖非普通目录 generated：%s" target))))
  (let ((backup (when (file-exists-p target)
                  (expand-file-name
                   (format ".loomacs-generated-backup-%s-%s"
                           (emacs-pid)
                           (substring (secure-hash 'sha256
                                                   (format "%s" (float-time)))
                                      0 8))
                   loomacs-root-directory))))
    (condition-case error-data
        (progn
          (when backup
            (rename-file target backup))
          ;; staging 位于仓库根目录的临时目录中，与 generated 同一文件系统。
          ;; 校验全部成功后才执行 rename，生成物不会逐文件暴露半完成状态。
          (rename-file staging-generated target)
          backup)
      (error
       (when (and backup
                  (file-directory-p backup)
                  (not (file-exists-p target)))
         (rename-file backup target))
       (signal 'loomacs-build-error
               (list (format "替换 generated 失败：%s"
                             (error-message-string error-data))))))))

(defun loomacs-build--restore-generated (target backup)
  "在发布失败后将 TARGET 恢复为 BACKUP。"
  (condition-case error-data
      (progn
        (when (file-directory-p target)
          (delete-directory target t))
        (when backup
          (rename-file backup target)))
    (error
     (signal 'loomacs-build-error
             (list (format "发布失败且恢复 generated 也失败：%s"
                           (error-message-string error-data)))))))

(defun loomacs-build (&optional root)
  "从 ROOT（默认 `loomacs-root-directory'）显式构建并发布 Loomacs。

成功返回激活的 Release 目录。该命令不刷新包索引、不安装包。"
  (interactive)
  (let* ((loomacs-root-directory
          (file-name-as-directory (expand-file-name (or root loomacs-root-directory))))
         (config-source (expand-file-name "config.org" loomacs-root-directory))
         (target (expand-file-name "generated" loomacs-root-directory))
         (lock nil)
         (staging-root nil)
         (staging-generated nil)
         (backup nil)
         (release nil)
         result)
    (loomacs-with-file-logging
      (setq lock (loomacs-build--acquire-lock))
      (unwind-protect
          (condition-case error-data
              (progn
                (unless (file-readable-p config-source)
                  (signal 'loomacs-build-error
                          (list (format "缺少构建入口：%s" config-source))))
                ;; 临时目录前缀位于仓库根，确保后续目录 rename 不跨文件系统。
                (setq staging-root
                      (make-temp-file
                       (expand-file-name ".loomacs-build-" loomacs-root-directory) t)
                      staging-generated (expand-file-name "generated" staging-root))
                (make-directory staging-generated t)
                (let* ((manifest-file
                        (expand-file-name "loomacs-manifest.el" staging-generated)))
                  (loomacs-tangle-file config-source manifest-file)
                  (let ((manifest (loomacs-manifest-read-file manifest-file)))
                    (loomacs-manifest-validate manifest loomacs-root-directory nil)
                    (dolist (module
                             (loomacs-module-topological-order
                              (loomacs-manifest-modules manifest)))
                      (loomacs-tangle-file
                       (loomacs-expand-safe-path
                        (plist-get module :source) loomacs-root-directory)
                       (loomacs-expand-safe-path
                        (plist-get module :output) staging-generated)))
                    (loomacs-build--write-metadata manifest staging-generated)
                    (loomacs-build--validate-staging manifest staging-generated)))
                (setq backup
                      (loomacs-build--replace-generated staging-generated target))
                ;; Release 创建或链接切换失败都属于未完成发布；恢复 Git 跟踪的
                ;; generated，current/previous 则由 release 层自行事务恢复。
                (condition-case release-error
                    (progn
                      (setq release (loomacs-release-create target))
                      (setq result (loomacs-release-activate release)))
                  (error
                   (when (and release (file-directory-p release))
                     (delete-directory release t))
                   (loomacs-build--restore-generated target backup)
                   (setq backup nil)
                   (signal (car release-error) (cdr release-error))))
                (when (and backup (file-directory-p backup))
                  ;; 删除旧工作副本失败不影响已验证 Release；留存目录比把成功构建
                  ;; 误报为失败并再次切换链接更安全，因此这里只记录告警。
                  (condition-case cleanup-error
                      (delete-directory backup t)
                    (error
                     (loomacs-log 'warning "旧 generated 备份未清理：%s"
                                  (error-message-string cleanup-error)))))
                (setq backup nil)
                (loomacs-log 'info "构建与发布完成：%s" result)
                result)
            (error
             (loomacs-log 'error "构建失败：%s"
                          (error-message-string error-data))
             (signal (car error-data) (cdr error-data))))
        (when (and staging-root (file-directory-p staging-root))
          (condition-case cleanup-error
              (delete-directory staging-root t)
            (error
             (loomacs-log 'warning "staging 未能清理：%s"
                          (error-message-string cleanup-error)))))
        (loomacs-build--release-lock lock)))))

(provide 'loomacs-build)
;;; loomacs-build.el ends here
