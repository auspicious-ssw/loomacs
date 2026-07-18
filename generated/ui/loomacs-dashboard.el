;;; loomacs-dashboard.el --- Loomacs Dashboard -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(eval-when-compile (require 'use-package))
(eval-when-compile
  (require 'recentf)
  (require 'bookmark))

(declare-function bookmark-maybe-load-default-file "bookmark" ())
(declare-function bookmark-save "bookmark" (&optional par))
(declare-function recentf-save-list "recentf" ())

(defface loomacs-dashboard-selection-face
  '((((class color) (background dark))
     (:background "#cba6f7" :foreground "#1e1e2e" :weight bold))
    (((class color) (background light))
     (:background "#8839ef" :foreground "#eff1f5" :weight bold))
    (t (:inverse-video t :weight bold)))
  "Dashboard 当前键盘选中项使用的 face。")

(defvar-local loomacs-dashboard-selection-overlay nil
  "当前 Dashboard buffer 中唯一的键盘选择 overlay。")

(defconst loomacs-dashboard-org-entry-migrations
  (mapcar (lambda (pair)
            (cons (expand-file-name (car pair) user-emacs-directory)
                  (expand-file-name (cdr pair) user-emacs-directory)))
          '(("init.el" . "config.org")
            ("README.md" . "README.org")
            ("docs/ARCHITECTURE.md" . "docs/ARCHITECTURE.org")
            ;; 旧 DECISIONS 已拆入框架文档，架构总览是兼容书签的稳定入口。
            ("docs/DECISIONS.md" . "docs/ARCHITECTURE.org")
            ("docs/DECISIONS.org" . "docs/ARCHITECTURE.org")
            ("docs/KEYMAPS.md" . "docs/KEYMAPS.org")
            ("docs/OPERATIONS.md" . "docs/OPERATIONS.org")
            ("docs/README.md" . "docs/README.org")
            ("docs/ROADMAP.md" . "docs/ROADMAP.org")))
  "Dashboard 本机状态中需迁移到 Org 的旧入口。")

(defun loomacs-dashboard--org-entry-for (path)
  "当 PATH 是已迁移的旧入口时返回对应 Org 文件。"
  (when (stringp path)
    (alist-get (expand-file-name path)
               loomacs-dashboard-org-entry-migrations nil nil #'string=)))

(defun loomacs-dashboard--migrate-org-entries ()
  "将 Recent Files 和 Bookmarks 中的精确旧配置入口迁移到 Org。"
  ;; 只改写本仓库精确旧路径，不能将其他项目仍有效的 README.md 一并替换。
  (let ((recentf-changed nil))
    (setq recentf-list
          (delete-dups
           (mapcar (lambda (path)
                     (if-let ((org-path (loomacs-dashboard--org-entry-for path)))
                         (progn
                           (setq recentf-changed t)
                           (abbreviate-file-name org-path))
                       path))
                   recentf-list)))
    (when recentf-changed
      (recentf-save-list)))

  (require 'bookmark)
  (bookmark-maybe-load-default-file)
  (let ((bookmark-changed nil))
    (dolist (bookmark bookmark-alist)
      (when-let* ((filename-cell (assq 'filename (cdr bookmark)))
                  (org-path
                   (loomacs-dashboard--org-entry-for (cdr filename-cell))))
        (setcdr filename-cell org-path)
        (setq bookmark-changed t)))
    (when bookmark-changed
      (bookmark-save))))

(defun loomacs-dashboard--button-overlay-at-point ()
  "返回 point 所在的 Dashboard widget overlay。"
  (catch 'button-overlay
    (dolist (overlay (overlays-at (point)))
      (when (overlay-get overlay 'button)
        (throw 'button-overlay overlay)))))

(defun loomacs-dashboard--update-selection ()
  "让 Dashboard 整项选择 overlay 跟随当前 widget。"
  (when (and (derived-mode-p 'dashboard-mode)
             (overlayp loomacs-dashboard-selection-overlay)
             (overlay-buffer loomacs-dashboard-selection-overlay))
    (if-let ((button-overlay (loomacs-dashboard--button-overlay-at-point)))
        (move-overlay loomacs-dashboard-selection-overlay
                      (overlay-start button-overlay)
                      (overlay-end button-overlay)
                      (current-buffer))
      (move-overlay loomacs-dashboard-selection-overlay
                    (point-min) (point-min) (current-buffer)))))

(defun loomacs-dashboard--apply-interaction-style ()
  "为当前 Dashboard buffer 建立唯一的整项键盘焦点。"
  ;; Dashboard 刷新会重建 widget，因此先删除旧选择层，永远只保留一个焦点。
  (dolist (overlay (overlays-in (point-min) (point-max)))
    (when (overlay-get overlay 'loomacs-dashboard-selection)
      (delete-overlay overlay)))

  (setq-local cursor-type nil
              loomacs-dashboard-selection-overlay
              (make-overlay (point-min) (point-min) (current-buffer)))
  (overlay-put loomacs-dashboard-selection-overlay
               'loomacs-dashboard-selection t)
  (overlay-put loomacs-dashboard-selection-overlay
               'face 'loomacs-dashboard-selection-face)
  (overlay-put loomacs-dashboard-selection-overlay 'priority 100)

  ;; 只移除鼠标悬停的第二高亮；手型指针、点击 action 和 widget keymap 保持不变。
  (dolist (overlay (overlays-in (point-min) (point-max)))
    (when (overlay-get overlay 'button)
      (overlay-put overlay 'mouse-face nil)))

  (add-hook 'post-command-hook #'loomacs-dashboard--update-selection nil t)
  (loomacs-dashboard--update-selection))

(use-package dashboard
  :if (package-installed-p 'dashboard)
  :ensure nil
  :demand t
  :hook (dashboard-mode . loomacs-dashboard--apply-interaction-style)
  :init
  (setq dashboard-startup-banner 'logo
        dashboard-banner-logo-title "Welcome back, SSW"
        dashboard-center-content t
        dashboard-vertically-center-content t
        dashboard-navigation-cycle t
        dashboard-display-icons-p (package-installed-p 'nerd-icons)
        dashboard-icon-type 'nerd-icons
        dashboard-set-heading-icons (package-installed-p 'nerd-icons)
        dashboard-set-file-icons (package-installed-p 'nerd-icons)
        dashboard-projects-backend 'project-el
        dashboard-items '((recents . 5)
                          (projects . 5)
                          (bookmarks . 5)))
  :config
  (dashboard-setup-startup-hook)
  (setq initial-buffer-choice #'dashboard-open))

;; 状态迁移依赖 recentf 已加载；如果用户停用 recentf，Dashboard 仍可降级启动。
(when (bound-and-true-p recentf-mode)
  (loomacs-dashboard--migrate-org-entries))

(provide 'loomacs-dashboard)
;;; loomacs-dashboard.el ends here
