;;; init.el --- 轻量、原生的 Emacs 配置 -*- lexical-binding: t; -*-

;; 基础体验
(setq inhibit-startup-screen t
      initial-scratch-message ""
      ring-bell-function #'ignore
      use-short-answers t
      sentence-end-double-space nil
      scroll-conservatively 101
      scroll-margin 3)

(setq-default indent-tabs-mode nil
              tab-width 4
              fill-column 100)

;; 持久状态与可清理缓存必须分开：清理 cache 不应丢失历史或 Customize，
;; Git 管理的配置目录也不应继续接收运行时写入。
(defconst ssw/cache-directory
  (file-name-as-directory
   (expand-file-name "emacs" (or (getenv "XDG_CACHE_HOME") "~/.cache")))
  "Emacs 可重建缓存目录。")

(defconst ssw/state-directory
  (file-name-as-directory
   (expand-file-name "emacs" (or (getenv "XDG_STATE_HOME") "~/.local/state")))
  "Emacs 本机持久状态目录。")

(let ((backup-dir (expand-file-name "backups/" ssw/cache-directory))
      (auto-save-dir (expand-file-name "auto-save/" ssw/cache-directory))
      (auto-save-list-dir (expand-file-name "auto-save-list/" ssw/cache-directory)))
  (dolist (directory (list ssw/state-directory backup-dir auto-save-dir auto-save-list-dir))
    (make-directory directory t)
    ;; history、备份与 autosave 可能包含本机路径或未提交内容，
    ;; 因此目录必须仅当前用户可读。
    (set-file-modes directory #o700))
  (setq backup-directory-alist `(("." . ,backup-dir))
        auto-save-file-name-transforms `((".*" ,auto-save-dir t))
        auto-save-list-file-prefix (expand-file-name ".saves-" auto-save-list-dir)
        custom-file (expand-file-name "custom.el" ssw/state-directory)
        savehist-file (expand-file-name "history" ssw/state-directory)
        save-place-file (expand-file-name "places" ssw/state-directory)
        recentf-save-file (expand-file-name "recentf" ssw/state-directory)
        project-list-file (expand-file-name "projects" ssw/state-directory)
        bookmark-default-file (expand-file-name "bookmarks" ssw/state-directory)))

;; Customize 是本机持久设置。加载失败时只跳过该文件，不能阻断主配置启动。
(when (file-exists-p custom-file)
  (condition-case error-data
      (load custom-file nil 'nomessage)
    (error
     (message "跳过无法加载的 Customize 文件：%s"
              (error-message-string error-data)))))

;; 第三方包使用 Emacs 内置 package.el 管理；包安装是显式维护动作，
;; 启动不联网。
(require 'package)
(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa" . "https://melpa.org/packages/")))
(package-initialize)

(defconst ssw/declared-packages '(batppuccin dashboard nerd-icons)
  "这套配置明确依赖的第三方包。")

;; 保留用户通过 package.el 记录的其他本机包，同时保证仓库声明的包可由
;; `package-install-selected-packages' 一次性显式安装。
(setq package-selected-packages
      (delete-dups (append ssw/declared-packages package-selected-packages)))

;; Emacs 29+ 内置 use-package；当前不默认自动安装所有包，避免隐藏依赖来源。
(require 'use-package)
(setq use-package-always-ensure nil)

;; Batppuccin 缺失或损坏时必须保持离线可启动，因此回退到内置 Modus 主题；
;; 不在启动路径调用 package-refresh-contents 或 package-install。
(defun ssw/load-preferred-theme ()
  "加载首选主题；不可用时安全回退到内置主题。"
  (condition-case error-data
      (if (package-installed-p 'batppuccin)
          (progn
            (require 'batppuccin)
            (load-theme 'batppuccin-mocha t))
        (load-theme 'modus-vivendi-tinted t)
        (message (concat "Batppuccin 未安装；当前使用内置主题。"
                         "可显式运行 M-x package-install-selected-packages")))
    (error
     (mapc #'disable-theme custom-enabled-themes)
     (load-theme 'modus-vivendi-tinted t)
     (message "Batppuccin 加载失败，已回退到内置主题：%s"
              (error-message-string error-data)))))

(ssw/load-preferred-theme)

;; Nerd Icons 只负责成熟插件提供的图标 API；字体由 Homebrew 独立管理。
;; 包缺失时 Dashboard 会退化为文字列表，不影响编辑器启动；字体由检查脚本和
;; 真实 GUI 验收保证存在，避免把缺字方框带入日常界面。
(use-package nerd-icons
  :if (package-installed-p 'nerd-icons)
  :ensure nil
  :demand t)

;; Dashboard 的条目由 widget 负责交互。键盘焦点使用独立 overlay 覆盖当前
;; widget 范围，避免 box/bar cursor 只压在图标边缘而无法表达“选中整项”。
(defface ssw/dashboard-selection-face
  '((((class color) (background dark))
     (:background "#cba6f7" :foreground "#1e1e2e" :weight bold))
    (((class color) (background light))
     (:background "#8839ef" :foreground "#eff1f5" :weight bold))
    (t (:inverse-video t :weight bold)))
  "Dashboard 当前键盘选中项使用的 face。")

(defvar-local ssw/dashboard-selection-overlay nil
  "当前 Dashboard buffer 中唯一的键盘选择 overlay。")

(defun ssw/dashboard-button-overlay-at-point ()
  "返回当前 point 所在的 Dashboard widget overlay。"
  (catch 'button-overlay
    (dolist (overlay (overlays-at (point)))
      (when (overlay-get overlay 'button)
        (throw 'button-overlay overlay)))))

(defun ssw/dashboard-update-selection ()
  "让 Dashboard 选择 overlay 跟随当前 widget。"
  (when (and (derived-mode-p 'dashboard-mode)
             (overlayp ssw/dashboard-selection-overlay)
             (overlay-buffer ssw/dashboard-selection-overlay))
    (if-let ((button-overlay (ssw/dashboard-button-overlay-at-point)))
        (move-overlay ssw/dashboard-selection-overlay
                      (overlay-start button-overlay)
                      (overlay-end button-overlay)
                      (current-buffer))
      (move-overlay ssw/dashboard-selection-overlay
                    (point-min) (point-min) (current-buffer)))))

(defun ssw/dashboard-apply-interaction-style ()
  "为当前 Dashboard buffer 建立唯一、整项可见的键盘焦点。"
  ;; Dashboard 刷新时会重新生成 widget；先删除旧选择 overlay，保证每个
  ;; buffer 永远只有一个选择状态，不残留已经失效的范围。
  (dolist (overlay (overlays-in (point-min) (point-max)))
    (when (overlay-get overlay 'ssw/dashboard-selection)
      (delete-overlay overlay)))

  ;; r/p/m、TAB 和方向键移动 point 后由整项高亮表达焦点，因此隐藏原生光标。
  (setq-local cursor-type nil
              ssw/dashboard-selection-overlay
              (make-overlay (point-min) (point-min) (current-buffer)))
  (overlay-put ssw/dashboard-selection-overlay
               'ssw/dashboard-selection t)
  (overlay-put ssw/dashboard-selection-overlay
               'face 'ssw/dashboard-selection-face)
  (overlay-put ssw/dashboard-selection-overlay 'priority 100)

  ;; Dashboard 在进入 major mode 前已经生成 widget overlay。取消 mouse-face
  ;; 只会移除持续高亮；插件的手型 pointer、点击 action 和 keymap 保持不变。
  (dolist (overlay (overlays-in (point-min) (point-max)))
    (when (overlay-get overlay 'button)
      (overlay-put overlay 'mouse-face nil)))

  ;; post-command-hook 是 buffer-local；离开 Dashboard 后不会影响普通编辑。
  (add-hook 'post-command-hook #'ssw/dashboard-update-selection nil t)
  (ssw/dashboard-update-selection))

;; Dashboard 使用成熟插件提供的标准组件与 hook；这里只选择内置 project.el
;; 后端、公开图标变量和展示内容，不维护自定义首页渲染逻辑。
(use-package dashboard
  :if (package-installed-p 'dashboard)
  :ensure nil
  :demand t
  :hook (dashboard-mode . ssw/dashboard-apply-interaction-style)
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
  ;; 官方建议 daemon/client 场景使用 initial-buffer-choice 打开 Dashboard。
  (setq initial-buffer-choice #'dashboard-open))

;; Fira Code 用于英文和代码，中文回退到 macOS 自带苹方，
;; 避免缺字或字形混杂。
(defconst ssw/default-font-height 170
  "默认字体高度；Emacs 以 1/10pt 表示，因此 170 等于 17pt。")

(defun ssw/apply-fonts (&optional frame)
  "为 FRAME 应用代码字体和中文回退字体。"
  (with-selected-frame (or frame (selected-frame))
    (when (find-font (font-spec :family "Fira Code"))
      (set-face-attribute 'default nil
                          :family "Fira Code"
                          :height ssw/default-font-height
                          :weight 'regular))
    (when (find-font (font-spec :family "PingFang SC"))
      (set-fontset-font t 'han (font-spec :family "PingFang SC") nil 'prepend))))

(ssw/apply-fonts)
;; daemon/client 创建的新图形窗口也必须获得相同字体，
;; 不能只设置启动时的首个 frame。
(add-hook 'after-make-frame-functions #'ssw/apply-fonts)

(delete-selection-mode 1)
(electric-pair-mode 1)
(global-auto-revert-mode 1)
(column-number-mode 1)
(show-paren-mode 1)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)

;; 统一使用 UTF-8，确保中文文件、剪贴板和终端内容正常显示。
(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8-unix)
(set-default-coding-systems 'utf-8-unix)

;; macOS 下 Option 作为 Meta，Command 保留为 Super，兼顾 Emacs 与系统快捷键。
(when (boundp 'ns-option-modifier)
  (setq ns-option-modifier 'meta
        ns-command-modifier 'super))

;; 记住最近文件、命令历史和光标位置。
(savehist-mode 1)
(save-place-mode 1)
(recentf-mode 1)
(setq recentf-max-saved-items 100)

;; 正常加载结束时立即恢复；early-init 注册的启动 hook 是异常路径兜底。
(when (fboundp 'ssw/restore-gc-settings)
  (ssw/restore-gc-settings))

(provide 'init)
;;; init.el ends here
