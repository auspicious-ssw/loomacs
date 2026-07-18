;;; loomacs-packages.el --- Loomacs 包管理 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(require 'package)

;; 变量由 Magit 定义，但必须在插件尚未加载时先关闭其隐式全局键位。
(defvar magit-define-global-key-bindings)

(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa" . "https://melpa.org/packages/"))
      ;; Magit 的隐式全局键位必须先关闭，再由模块明确声明。
      magit-define-global-key-bindings nil)

(package-initialize)

(defvar loomacs-declared-packages nil
  "Loomacs 所有已启用模块明确声明的第三方包。")

(defun loomacs-register-packages (&rest packages)
  "注册 PACKAGES，并保留 package.el 已记录的其他本机包。"
  (setq loomacs-declared-packages
        (delete-dups (append loomacs-declared-packages packages))
        package-selected-packages
        (delete-dups (append loomacs-declared-packages
                             package-selected-packages))))

;; use-package 只描述加载时机；缺包路径必须安全降级。
(require 'use-package)
(setq use-package-always-ensure nil)

(provide 'loomacs-packages)
;;; loomacs-packages.el ends here
