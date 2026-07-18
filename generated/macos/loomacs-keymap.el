;;; loomacs-keymap.el --- Loomacs macOS 修饰键 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(eval-when-compile
  (defvar ns-option-modifier)
  (defvar ns-command-modifier))

(when (and (boundp 'ns-option-modifier)
           (boundp 'ns-command-modifier))
  (setq ns-option-modifier 'meta
        ns-command-modifier 'super))

(provide 'loomacs-keymap)
;;; loomacs-keymap.el ends here
