;;; loomacs-profile-default.el --- Loomacs 默认 Profile -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>
;; Generated from profiles/default.org.  Do not edit directly.

(defcustom loomacs-profile 'default
  "当前 Loomacs Profile。"
  :type 'symbol
  :group 'loomacs)

(defcustom loomacs-font-family "Fira Code"
  "Loomacs 默认等宽字体。"
  :type 'string
  :group 'loomacs)

(defcustom loomacs-font-height 170
  "Loomacs 默认字体高度；170 对应约 17pt。"
  :type 'integer
  :group 'loomacs)

(defcustom loomacs-cjk-font-family "PingFang SC"
  "Loomacs 默认中文字体。"
  :type 'string
  :group 'loomacs)

(defcustom loomacs-enabled-domains
  '(core navigation ui completion git org lsp ai)
  "默认启用的 Loomacs 功能领域。"
  :type '(repeat symbol)
  :group 'loomacs)

(provide 'loomacs-profile-default)
;;; loomacs-profile-default.el ends here
