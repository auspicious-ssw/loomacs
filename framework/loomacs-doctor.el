;;; loomacs-doctor.el --- Loomacs 环境与构建诊断 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW
;; URL: https://github.com/auspicious-ssw/loomacs
;; Package-Requires: ((emacs "30.2"))

;;; Commentary:

;; Doctor 只读检查 Emacs、Manifest、生成物摘要、Release、第三方包锁、字体、
;; 外部命令和认证条目是否存在。它不联网、不安装、不升级，也不输出认证内容。

;;; Code:

(require 'seq)
(require 'auth-source)
(require 'package)
(require 'loomacs-release)
(require 'loomacs-tangle)

(defvar loomacs-doctor--issues nil
  "当前 Doctor 运行收集的问题。")

(defvar loomacs-build-metadata nil
  "由 generated/loomacs-build-metadata.el 设置的构建摘要。")

(defvar loomacs-package-lock nil
  "由 lock/packages.el 设置的包锁。")

(defvar loomacs-package-lock-direct nil
  "由 lock/packages.el 设置的直接依赖列表。")

(defun loomacs-doctor-build-lock-directory ()
  "返回构建互斥锁目录，不加载构建器或 Org。"
  (expand-file-name ".loomacs-build.lock" loomacs-root-directory))

(defun loomacs-doctor--add (severity code format-string &rest arguments)
  "添加 SEVERITY、CODE 和格式化消息到当前诊断结果。"
  (push (list :severity severity
              :code code
              :message (apply #'format format-string arguments))
        loomacs-doctor--issues))

(defun loomacs-doctor--load-manifest (directory label)
  "验证 DIRECTORY 的 Manifest，以 LABEL 记录问题并返回 Manifest。"
  (condition-case error-data
      (let* ((file (expand-file-name "loomacs-manifest.el" directory))
             (manifest (loomacs-manifest-read-file file)))
        (loomacs-manifest-validate manifest nil directory)
        (loomacs-doctor--add 'info 'manifest-valid
                             "%s Manifest 与模块静态校验通过" label)
        manifest)
    (error
     (loomacs-doctor--add 'error 'manifest-invalid
                          "%s 无效：%s" label
                          (error-message-string error-data))
     nil)))

(defun loomacs-doctor--check-build-metadata
    (generated-directory manifest check-sources label)
  "复核 GENERATED-DIRECTORY 的构建摘要与 MANIFEST。

CHECK-SOURCES 非 nil 时同时比较当前 Org 源码；LABEL 用于可读诊断。"
  (let ((metadata-file (expand-file-name "loomacs-build-metadata.el"
                                         generated-directory))
        problem)
    (if (not (file-readable-p metadata-file))
        (progn
          (setq problem t)
          (loomacs-doctor--add 'error 'metadata-missing
                               "%s 缺少确定性构建元数据：%s"
                               label metadata-file))
      (condition-case error-data
          (let ((loomacs-build-metadata nil))
            (load metadata-file nil 'nomessage t)
            (unless (and (listp loomacs-build-metadata)
                         (equal (plist-get loomacs-build-metadata :format) 1))
              (error "构建元数据格式无效"))
            (when check-sources
              (let ((expected-sources
                     (delete-dups
                      (cons "config.org"
                            (mapcar (lambda (module)
                                      (plist-get module :source))
                                    (loomacs-manifest-modules manifest)))))
                    (actual-sources
                     (mapcar #'car (plist-get loomacs-build-metadata :sources))))
                (unless (equal expected-sources actual-sources)
                  (setq problem t)
                  (loomacs-doctor--add
                   'error 'metadata-source-set-mismatch
                   "构建元数据的源码集合与 Manifest 不一致；请运行 scripts/build")))
              (dolist (entry (plist-get loomacs-build-metadata :sources))
                (let ((relative (car-safe entry))
                      (expected (cdr-safe entry)))
                  (unless (and (loomacs-safe-relative-path-p relative)
                               (stringp expected))
                    (error "源码摘要条目无效：%S" entry))
                  (let ((source (loomacs-expand-safe-path
                                 relative loomacs-root-directory)))
                    (cond
                     ((not (file-readable-p source))
                      (setq problem t)
                      (loomacs-doctor--add 'error 'source-missing
                                           "构建元数据中的源码不可读：%s" relative))
                     ((not (loomacs-path-inside-directory-p
                            source loomacs-root-directory))
                      (setq problem t)
                      (loomacs-doctor--add 'error 'source-outside-root
                                           "源码符号链接逃离仓库：%s" relative))
                     ((not (string-equal expected (loomacs-file-sha256 source)))
                      (setq problem t)
                      (loomacs-doctor--add
                       'error 'generated-stale
                       "生成物已落后于源码：%s；请运行 scripts/build" relative)))))))
            (let ((expected-outputs
                   (delete-dups
                    (cons "loomacs-manifest.el"
                          (mapcar (lambda (module)
                                    (plist-get module :output))
                                  (loomacs-manifest-modules manifest)))))
                  (actual-outputs
                   (mapcar #'car (plist-get loomacs-build-metadata :outputs))))
              (unless (equal expected-outputs actual-outputs)
                (setq problem t)
                (loomacs-doctor--add
                 'error 'metadata-output-set-mismatch
                 "%s 的生成物摘要集合与 Manifest 不一致" label)))
            (dolist (entry (plist-get loomacs-build-metadata :outputs))
              (let ((relative (car-safe entry))
                    (expected (cdr-safe entry)))
                (unless (and (loomacs-safe-relative-path-p relative "el")
                             (stringp expected))
                  (error "生成物摘要条目无效：%S" entry))
                (let ((output (loomacs-expand-safe-path
                               relative generated-directory)))
                  (cond
                   ((not (file-readable-p output))
                    (setq problem t)
                    (loomacs-doctor--add 'error 'generated-output-missing
                                         "%s 的生成物不可读：%s" label relative))
                   ((not (loomacs-path-inside-directory-p
                          output generated-directory))
                    (setq problem t)
                    (loomacs-doctor--add 'error 'generated-output-outside-root
                                         "%s 的生成物逃离目录：%s" label relative))
                   ((not (string-equal expected (loomacs-file-sha256 output)))
                    (setq problem t)
                    (loomacs-doctor--add 'error 'generated-modified
                                         "%s 的生成物被直接修改：%s"
                                         label relative))))))
            (unless problem
              (if check-sources
                  (loomacs-doctor--add 'info 'generated-fresh
                                       "Git 生成物、Org 源码与摘要一致")
                (loomacs-doctor--add 'info 'release-integrity-valid
                                     "%s 的生成物摘要一致" label))))
        (error
         (setq problem t)
         (loomacs-doctor--add 'error 'metadata-invalid
                              "%s 构建元数据无效：%s"
                              label (error-message-string error-data)))))
    (not problem)))

(defun loomacs-doctor--package-description (package)
  "返回已激活 PACKAGE 的 `package-desc'，不存在时返回 nil。"
  (car (cdr (assq package package-alist))))

(defun loomacs-doctor--load-package-lock ()
  "加载并返回 lock/packages.el；无效时记录错误。"
  (let ((file (loomacs-path "lock" "packages.el")))
    (if (not (file-readable-p file))
        (progn
          (loomacs-doctor--add 'error 'package-lock-missing
                               "缺少包锁：%s" file)
          nil)
      (condition-case error-data
          (let ((loomacs-package-lock nil)
                (loomacs-package-lock-direct nil))
            (load file nil 'nomessage t)
            (unless (and (proper-list-p loomacs-package-lock)
                         (proper-list-p loomacs-package-lock-direct))
              (error "包锁变量格式无效"))
            (list loomacs-package-lock loomacs-package-lock-direct))
        (error
         (loomacs-doctor--add 'error 'package-lock-invalid
                              "包锁加载失败：%s"
                              (error-message-string error-data))
         nil)))))

(defun loomacs-doctor--check-packages (manifest)
  "检查 MANIFEST 声明包的安装版本与包锁。"
  (when manifest
    (require 'package)
    ;; -Q 下显式指向仓库本机 elpa；package-initialize 只读取本机描述与 autoload，
    ;; 不刷新 archive、不安装或升级。
    (let ((package-user-dir (expand-file-name "elpa" loomacs-root-directory)))
      (package-initialize))
    (let* ((lock-data (loomacs-doctor--load-package-lock))
           (lock (car lock-data))
           (direct (cadr lock-data))
           (declared (loomacs-manifest-packages manifest)))
      (when lock-data
        (dolist (package declared)
          (let* ((entry (assq package lock))
                 (properties (cdr entry))
                 (expected-version (plist-get properties :version))
                 (expected-commit (plist-get properties :commit))
                 (description (loomacs-doctor--package-description package)))
            (cond
             ((null entry)
              (loomacs-doctor--add 'error 'package-unlocked
                                   "Manifest 声明包 %S，但包锁没有该条目" package))
             ((null description)
              (loomacs-doctor--add 'error 'package-missing
                                   "第三方包未安装：%S（锁定 %s）"
                                   package expected-version))
             (t
              (let* ((actual-version
                      (package-version-join (package-desc-version description)))
                     (extras (package-desc-extras description))
                     (actual-commit (alist-get :commit extras)))
                (unless (string-equal expected-version actual-version)
                  (loomacs-doctor--add 'error 'package-version-drift
                                       "包 %S 版本漂移：锁定 %s，实际 %s"
                                       package expected-version actual-version))
                ;; Archive 可能不提供 commit；只有双方都能给出证据时比较，不把
                ;; “元数据没有 commit”推断成版本错误。
                (when (and expected-commit actual-commit
                           (not (string-equal expected-commit actual-commit)))
                  (loomacs-doctor--add 'error 'package-commit-drift
                                       "包 %S commit 漂移：锁定 %s，实际 %s"
                                       package expected-commit actual-commit)))))))
        (dolist (package direct)
          (unless (memq package declared)
            (loomacs-doctor--add 'warning 'package-lock-unused-direct
                                 "包锁标为直接依赖，但 Manifest 未声明：%S" package)))
        (unless (seq-some
                 (lambda (issue)
                   (memq (plist-get issue :code)
                         '(package-unlocked package-missing package-version-drift
                           package-commit-drift)))
                 loomacs-doctor--issues)
          (loomacs-doctor--add 'info 'packages-valid
                               "Manifest 声明的 %d 个第三方包与包锁一致"
                               (length declared)))))))

(defun loomacs-doctor--font-available-p (font-name)
  "FONT-NAME 可被当前 Emacs 字体后端发现时返回非 nil。"
  (or (condition-case nil
          (and (fboundp 'find-font)
               (find-font (font-spec :name font-name)))
        (error nil))
      ;; `emacs --batch' 没有图形 frame，macOS 上 find-font 会对已安装字体返回
      ;; nil。优先使用本机 fontconfig 的只读枚举作为 batch 证据，避免把“当前
      ;; 无 GUI 字体后端”误报成“字体未安装”。
      (when-let ((fc-list (executable-find "fc-list")))
        (condition-case nil
            (with-temp-buffer
              (and (zerop (call-process fc-list nil t nil ":" "family"))
                   (goto-char (point-min))
                   (search-forward font-name nil t)))
          (error nil)))))

(defun loomacs-doctor--check-requirements (manifest)
  "检查 MANIFEST 顶层 :requirements 声明的本机能力。"
  (let ((requirements (plist-get manifest :requirements)))
    (dolist (font (plist-get requirements :fonts))
      (unless (loomacs-doctor--font-available-p font)
        (loomacs-doctor--add 'warning 'font-missing
                             "字体不可用：%s" font)))
    (dolist (executable (plist-get requirements :executables))
      (unless (and (stringp executable)
                   (if (file-name-absolute-p executable)
                       (file-executable-p executable)
                     (executable-find executable)))
        (loomacs-doctor--add 'warning 'executable-missing
                             "外部命令不可用：%s" executable)))
    (dolist (group (plist-get requirements :optional-executable-groups))
      (let ((label (car-safe group))
            (candidates (cdr-safe group)))
        (if (and (symbolp label)
                 (proper-list-p candidates)
                 (seq-every-p #'stringp candidates))
            (let ((available
                   (seq-find (lambda (candidate)
                               (if (file-name-absolute-p candidate)
                                   (file-executable-p candidate)
                                 (executable-find candidate)))
                             candidates)))
              (if available
                  (loomacs-doctor--add 'info 'optional-executable-available
                                       "可选工具组 %S 使用 %s" label available)
                ;; LSP server 属于按语言启用的外部能力；全缺只影响对应语言，
                ;; 不能把通用 Emacs 启动错误地判为失败。
                (loomacs-doctor--add
                 'warning 'optional-executable-group-missing
                 "可选工具组 %S 均不可用：%s"
                 label (mapconcat #'identity candidates ", "))))
          (loomacs-doctor--add 'warning 'requirement-invalid
                               "可选工具组声明无效：%S" group))))
    (dolist (host (plist-get requirements :auth-hosts))
      (condition-case error-data
          (progn
            (require 'auth-source)
            ;; 只判断是否存在匹配项，不取出或打印 :secret，也不把认证对象保存在
            ;; Doctor 结果里。
            (unless (auth-source-search :host host :max 1)
              (loomacs-doctor--add 'warning 'auth-missing
                                   "auth-source 没有主机 %s 的条目" host)))
        (error
         (loomacs-doctor--add 'warning 'auth-check-failed
                              "无法检查 auth-source 主机 %s：%s"
                              host (error-message-string error-data)))))))

(defun loomacs-doctor--check-release-links ()
  "检查 current/previous Release 链接是否完整。"
  (let ((current-link (loomacs-release-current-link))
        (previous-link (loomacs-release-previous-link)))
    (cond
     ((file-symlink-p current-link)
      (unless (loomacs-release-current-directory)
        (loomacs-doctor--add 'error 'current-release-invalid
                             "current Release 链接无效：%s" current-link)))
     ((file-exists-p current-link)
      (loomacs-doctor--add 'error 'current-release-not-link
                           "current 必须是符号链接：%s" current-link))
     (t
      (loomacs-doctor--add 'info 'release-not-created
                           "尚无本机 Release；启动使用 Git generated")))
    (when (or (file-symlink-p previous-link) (file-exists-p previous-link))
      (unless (loomacs-release-previous-directory)
        (loomacs-doctor--add 'warning 'previous-release-invalid
                             "previous Release 链接无效，暂时不能回滚")))))

(defun loomacs-doctor-run ()
  "执行只读诊断并返回 issue plist 列表。"
  (let ((loomacs-doctor--issues nil)
        manifest)
    (if (version< emacs-version loomacs-minimum-emacs-version)
        (loomacs-doctor--add 'error 'emacs-version
                             "当前只验证 Emacs %s，实际为 %s"
                             loomacs-minimum-emacs-version emacs-version)
      (loomacs-doctor--add 'info 'emacs-version
                           "Emacs 版本满足当前已验证基线：%s" emacs-version))
    (let ((tracked (loomacs-generated-directory)))
      (setq manifest (loomacs-doctor--load-manifest tracked "Git generated"))
      (when manifest
        (loomacs-doctor--check-build-metadata
         tracked manifest t "Git generated")))
    (let ((active (loomacs-release-active-directory)))
      (unless (string-equal (file-truename active)
                            (file-truename (loomacs-generated-directory)))
        (let ((active-manifest
               (loomacs-doctor--load-manifest active "current Release")))
          (when active-manifest
            (loomacs-doctor--check-build-metadata
             active active-manifest nil "current Release"))
          (setq manifest (or active-manifest manifest)))))
    (loomacs-doctor--check-release-links)
    (when (file-directory-p (loomacs-doctor-build-lock-directory))
      (loomacs-doctor--add 'warning 'build-lock-present
                           "检测到构建锁；可能正在构建或上次异常退出：%s"
                           (loomacs-doctor-build-lock-directory)))
    (loomacs-doctor--check-packages manifest)
    (when manifest
      (loomacs-doctor--check-requirements manifest))
    (nreverse loomacs-doctor--issues)))

(defun loomacs-doctor-print (issues)
  "把 ISSUES 以稳定的单行格式打印到标准输出。"
  (dolist (issue issues)
    (princ (format "%-7s %-30s %s\n"
                   (upcase (symbol-name (plist-get issue :severity)))
                   (symbol-name (plist-get issue :code))
                   (plist-get issue :message)))))

(defun loomacs-doctor-batch ()
  "运行 Doctor，打印结果，并以是否存在 error 设置进程退出码。"
  (let ((issues (loomacs-doctor-run)))
    (loomacs-doctor-print issues)
    (kill-emacs
     (if (seq-some (lambda (issue)
                     (eq (plist-get issue :severity) 'error))
                   issues)
         1
       0))))

(provide 'loomacs-doctor)
;;; loomacs-doctor.el ends here
