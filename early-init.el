;;; early-init.el --- Loomacs 启动早期配置 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(declare-function tool-bar-mode "tool-bar" (&optional arg))
(declare-function scroll-bar-mode "scroll-bar" (&optional arg))

(defconst loomacs-gc-cons-threshold-normal (* 16 1024 1024)
  "Emacs 进入交互阶段后的 GC 内存阈值。")

(defconst loomacs-gc-cons-percentage-normal 0.1
  "Emacs 进入交互阶段后的 GC 比例阈值。")

(defun loomacs-restore-gc-settings ()
  "恢复适合交互使用的 GC 参数。"
  (setq gc-cons-threshold loomacs-gc-cons-threshold-normal
        gc-cons-percentage loomacs-gc-cons-percentage-normal))

;; 启动时暂时放宽 GC，减少初始化停顿。恢复 Hook 在 early-init 阶段注册，
;; 即使 init.el 中途报错，Emacs 完成启动收尾时仍会恢复交互阈值。
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6
      package-enable-at-startup nil)
(add-hook 'emacs-startup-hook #'loomacs-restore-gc-settings)

;; 用户需要占满当前显示器工作区、同时保留 macOS 菜单栏和 Dock。maximized
;; 比固定像素更能适配分辨率、Dock 位置和 daemon/client 创建的新 frame。
(setq frame-resize-pixelwise t
      window-resize-pixelwise t)
(add-to-list 'initial-frame-alist '(fullscreen . maximized))
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; 在 frame 显示前关闭不使用的元素，减少启动闪烁。
(menu-bar-mode -1)
;; 无 GUI 的 Homebrew/CI 构建可能没有工具栏或滚动条函数；这些只是外观能力，
;; 缺失时跳过，不能阻断基础 Emacs 启动。
(when (fboundp 'tool-bar-mode)
  (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1))

(provide 'early-init)
;;; early-init.el ends here
