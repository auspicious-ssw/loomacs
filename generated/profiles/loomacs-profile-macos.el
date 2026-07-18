;;; loomacs-profile-macos.el --- Loomacs macOS Profile -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>
;; Generated from profiles/macos.org.  Do not edit directly.

(defvar loomacs-profile)
(defvar loomacs-enabled-domains)

(when (eq system-type 'darwin)
  (setq loomacs-profile 'macos)
  (add-to-list 'loomacs-enabled-domains 'macos))

(provide 'loomacs-profile-macos)
;;; loomacs-profile-macos.el ends here
