;;; loomacs-macos.el --- Loomacs macOS 领域 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(declare-function loomacs-register-packages "loomacs-packages" (&rest packages))

(defconst loomacs-macos-modules
  '(loomacs-environment
    loomacs-frame
    loomacs-font
    loomacs-input-source
    loomacs-keymap)
  "macOS 领域的有序子模块 feature 清单。")

(defconst loomacs-macos-packages
  '(sis)
  "macOS 领域直接使用的第三方包。")

(apply #'loomacs-register-packages loomacs-macos-packages)

(provide 'loomacs-macos)
;;; loomacs-macos.el ends here
