;;; loomacs-keymap.el --- Loomacs macOS 修饰键 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(when (boundp 'ns-option-modifier)
  (setq ns-option-modifier 'meta
        ns-command-modifier 'super))

(provide 'loomacs-keymap)
;;; loomacs-keymap.el ends here
