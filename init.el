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
        recentf-save-file (expand-file-name "recentf" ssw/state-directory)))

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

;; Dashboard 使用成熟插件提供的标准组件与 hook；这里只选择内置 project.el
;; 后端、公开图标变量和展示内容，不维护自定义首页渲染逻辑。
(use-package dashboard
  :if (package-installed-p 'dashboard)
  :ensure nil
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
(defun ssw/apply-fonts (&optional frame)
  "为 FRAME 应用代码字体和中文回退字体。"
  (with-selected-frame (or frame (selected-frame))
    (when (find-font (font-spec :family "Fira Code"))
      (set-face-attribute 'default nil :family "Fira Code" :height 150 :weight 'regular))
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
