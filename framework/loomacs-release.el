;;; loomacs-release.el --- Loomacs Release 与回滚 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW
;; URL: https://github.com/auspicious-ssw/loomacs
;; Package-Requires: ((emacs "30.2"))

;;; Commentary:

;; 每次成功构建把已验证 generated 快照复制到 XDG state Release，并用 current
;; 与 previous 符号链接记录可运行版本。回滚只交换两个已验证快照，不改 Git。

;;; Code:

(require 'loomacs-log)
(require 'loomacs-module)

(define-error 'loomacs-release-error "Loomacs Release 操作失败")

(defun loomacs-release-current-link ()
  "返回 current Release 链接路径。"
  (expand-file-name "current" (loomacs-release-directory)))

(defun loomacs-release-previous-link ()
  "返回 previous Release 链接路径。"
  (expand-file-name "previous" (loomacs-release-directory)))

(defun loomacs-release--new-id ()
  "生成可读且在单机上唯一的 Release ID。"
  (let* ((stamp (format-time-string "%Y%m%dT%H%M%S"))
         (entropy (format "%s:%s:%s" (float-time) (emacs-pid) (random)))
         (suffix (substring (secure-hash 'sha256 entropy) 0 10)))
    (format "%s-%s" stamp suffix)))

(defun loomacs-release--valid-directory (directory)
  "DIRECTORY 是有效 Release 时返回规范化目录，否则返回 nil。"
  (when (and directory (file-directory-p directory))
    (let* ((release-root (file-truename (loomacs-release-directory)))
           (candidate (file-truename directory))
           (manifest-file (expand-file-name "loomacs-manifest.el" candidate)))
      (when (and (file-in-directory-p candidate release-root)
                 (file-readable-p manifest-file))
        (condition-case nil
            (let ((manifest (loomacs-manifest-read-file manifest-file)))
              (loomacs-manifest-validate manifest nil candidate)
              (file-name-as-directory candidate))
          (error nil))))))

(defun loomacs-release--link-directory (link)
  "返回 LINK 指向的有效 Release 目录，否则返回 nil。"
  (when (file-symlink-p link)
    (loomacs-release--valid-directory
     (expand-file-name (file-symlink-p link)
                       (file-name-directory link)))))

(defun loomacs-release-current-directory ()
  "返回 current 指向的有效 Release 目录，否则返回 nil。"
  (loomacs-release--link-directory (loomacs-release-current-link)))

(defun loomacs-release-previous-directory ()
  "返回 previous 指向的有效 Release 目录，否则返回 nil。"
  (loomacs-release--link-directory (loomacs-release-previous-link)))

(defun loomacs-release-active-directory ()
  "返回启动应使用的生成目录。

全新克隆还没有本机 Release 时使用 Git 跟踪的 generated；一旦显式 build 成功，
current Release 成为运行版本，使 rollback 无需改写仓库文件。"
  (or (loomacs-release-current-directory)
      (loomacs-generated-directory)))

(defun loomacs-release--replace-link (link target-name)
  "将 LINK 安全替换为指向同目录 TARGET-NAME 的相对链接。

TARGET-NAME 为 nil 时删除 LINK。临时链接与目标位于同一目录，rename 不会跨
文件系统；失败时不会生成指向半成品目录的 current。"
  (let ((temporary (format "%s.tmp-%s" link (emacs-pid))))
    (when (or (file-exists-p temporary) (file-symlink-p temporary))
      (delete-file temporary))
    (if (null target-name)
        (when (or (file-exists-p link) (file-symlink-p link))
          (delete-file link))
      (make-symbolic-link target-name temporary)
      (rename-file temporary link t))))

(defun loomacs-release--link-name (link)
  "返回 LINK 保存的相对目标名称，否则返回 nil。"
  (when (file-symlink-p link)
    (file-symlink-p link)))

(defun loomacs-release-create (generated-directory)
  "从已验证的 GENERATED-DIRECTORY 创建 Release，返回其目录。"
  (let* ((source (file-name-as-directory
                  (expand-file-name generated-directory)))
         (manifest-file (expand-file-name "loomacs-manifest.el" source))
         (manifest (loomacs-manifest-read-file manifest-file))
         (release-root (loomacs-ensure-private-directory
                        (loomacs-release-directory)))
         (id (loomacs-release--new-id))
         (destination (expand-file-name id release-root)))
    (loomacs-manifest-validate manifest nil source)
    (condition-case error-data
        (progn
          (copy-directory source destination t t)
          (set-file-modes destination #o700)
          (let ((metadata (expand-file-name "loomacs-release-metadata.el"
                                            destination)))
            (with-temp-file metadata
              (insert ";;; 自动生成的本机 Release 元数据；不属于 Git 源码。\n")
              (prin1 `(:format 1
                       :id ,id
                       :created-at ,(format-time-string "%Y-%m-%dT%H:%M:%S%z")
                       :framework-version ,loomacs-version)
                     (current-buffer))
              (insert "\n"))
            (set-file-modes metadata #o600))
          destination)
      (error
       (when (file-directory-p destination)
         (delete-directory destination t))
       (signal 'loomacs-release-error
               (list (format "创建 Release 失败：%s"
                             (error-message-string error-data))))))))

(defun loomacs-release-activate (release-directory)
  "激活 RELEASE-DIRECTORY，并把原 current 保存为 previous。"
  (let* ((valid (loomacs-release--valid-directory release-directory))
         (release-root (loomacs-ensure-private-directory
                        (loomacs-release-directory)))
         (current (loomacs-release-current-link))
         (previous (loomacs-release-previous-link))
         (old-current (when (loomacs-release-current-directory)
                        (loomacs-release--link-name current)))
         (old-previous (loomacs-release--link-name previous)))
    (unless valid
      (signal 'loomacs-release-error
              (list (format "拒绝激活无效 Release：%s" release-directory))))
    (when (and (file-exists-p current) (not (file-symlink-p current)))
      (signal 'loomacs-release-error
              (list (format "拒绝覆盖非符号链接 current：%s" current))))
    (when (and (file-exists-p previous) (not (file-symlink-p previous)))
      (signal 'loomacs-release-error
              (list (format "拒绝覆盖非符号链接 previous：%s" previous))))
    (let ((new-name (file-name-nondirectory (directory-file-name valid))))
      (unless (file-directory-p (expand-file-name new-name release-root))
        (signal 'loomacs-release-error (list "Release 不在状态目录内")))
      (condition-case error-data
          (progn
            (loomacs-release--replace-link previous old-current)
            (loomacs-release--replace-link current new-name)
            (loomacs-log 'info "已激活 Release %s" new-name)
            valid)
        (error
         ;; 两个链接无法真正同时 rename；若第二步失败，立即恢复原链接，保证
         ;; 启动不会被指向一个只完成一半的 Release 切换。
         (ignore-errors (loomacs-release--replace-link current old-current))
         (ignore-errors (loomacs-release--replace-link previous old-previous))
         (signal 'loomacs-release-error
                 (list (format "激活 Release 失败：%s"
                               (error-message-string error-data)))))))))

(defun loomacs-release-rollback ()
  "交换 current 与 previous Release，并返回新的 current 目录。"
  (interactive)
  (let* ((current (loomacs-release-current-link))
         (previous (loomacs-release-previous-link))
         (current-name (loomacs-release--link-name current))
         (previous-name (loomacs-release--link-name previous))
         (current-directory (loomacs-release-current-directory))
         (previous-directory (loomacs-release-previous-directory)))
    (unless (and current-directory previous-directory)
      (signal 'loomacs-release-error
              (list "没有同时有效的 current 与 previous，无法回滚")))
    (condition-case error-data
        (progn
          (loomacs-release--replace-link current previous-name)
          (loomacs-release--replace-link previous current-name)
          (loomacs-log 'info "已回滚到 Release %s" previous-name)
          (loomacs-release-current-directory))
      (error
       (ignore-errors (loomacs-release--replace-link current current-name))
       (ignore-errors (loomacs-release--replace-link previous previous-name))
       (signal 'loomacs-release-error
               (list (format "回滚失败：%s"
                             (error-message-string error-data))))))))

(provide 'loomacs-release)
;;; loomacs-release.el ends here
