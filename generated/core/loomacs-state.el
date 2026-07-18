;;; loomacs-state.el --- Loomacs 状态与缓存 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

;; 这些变量分别由对应内置模块定义。State 只提前指定持久化路径，不为了设置
;; 路径而在启动早期加载全部导航模块。
(defvar savehist-file)
(defvar save-place-file)
(defvar recentf-save-file)
(defvar project-list-file)
(defvar bookmark-default-file)

(defconst loomacs-editor-state-directory
  (loomacs-state-directory)
  "Emacs 编辑状态目录。")

(defconst loomacs-editor-cache-root-directory
  (loomacs-editor-cache-directory)
  "Emacs 编辑缓存目录。")

(defconst loomacs-legacy-state-root
  (file-name-as-directory
   (expand-file-name "emacs" (or (getenv "XDG_STATE_HOME") "~/.local/state")))
  "旧版配置的状态目录，供无覆盖迁移与 Recent Files 过滤使用。")

(defun loomacs-state--migrate-legacy-file (name)
  "在新状态 NAME 不存在时，从旧目录复制一份。"
  (let ((source (expand-file-name name loomacs-legacy-state-root))
        (destination (expand-file-name name loomacs-editor-state-directory)))
    ;; 旧文件保留不动，且永不覆盖新运行已产生的真实状态。
    (when (and (file-regular-p source)
               (not (file-exists-p destination)))
      (copy-file source destination nil t nil t)
      (set-file-modes destination #o600))))

(let ((backup-directory
       (file-name-as-directory
        (expand-file-name "backups" loomacs-editor-cache-root-directory)))
      (auto-save-directory
       (file-name-as-directory
        (expand-file-name "auto-save" loomacs-editor-cache-root-directory)))
      (auto-save-list-directory
       (file-name-as-directory
        (expand-file-name "auto-save-list" loomacs-editor-cache-root-directory))))
  (dolist (directory (list loomacs-state-root
                           loomacs-editor-state-directory
                           loomacs-cache-root
                           loomacs-editor-cache-root-directory
                           backup-directory
                           auto-save-directory
                           auto-save-list-directory))
    (make-directory directory t)
    ;; 历史、备份和 autosave 可能包含本机路径或未提交内容。
    (set-file-modes directory #o700))

  (dolist (name '("custom.el" "history" "places" "recentf"
                  "projects" "bookmarks"))
    (loomacs-state--migrate-legacy-file name))

  (setq backup-directory-alist `(("." . ,backup-directory))
        auto-save-file-name-transforms `((".*" ,auto-save-directory t))
        auto-save-list-file-prefix
        (expand-file-name ".saves-" auto-save-list-directory)
        custom-file (expand-file-name "custom.el" loomacs-editor-state-directory)
        savehist-file (expand-file-name "history" loomacs-editor-state-directory)
        save-place-file (expand-file-name "places" loomacs-editor-state-directory)
        recentf-save-file (expand-file-name "recentf" loomacs-editor-state-directory)
        project-list-file (expand-file-name "projects" loomacs-editor-state-directory)
        bookmark-default-file
        (expand-file-name "bookmarks" loomacs-editor-state-directory)))

;; Customize 是本机状态；单个损坏文件不能阻断整个编辑器启动。
(when (file-exists-p custom-file)
  (condition-case error-data
      (load custom-file nil 'nomessage)
    (error
     (message "跳过无法加载的 Customize 文件：%s"
              (error-message-string error-data)))))

(provide 'loomacs-state)
;;; loomacs-state.el ends here
