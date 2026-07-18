;;; loomacs-nerd-icons.el --- Loomacs Nerd Icons -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(eval-when-compile (require 'use-package))

(use-package nerd-icons
  :if (package-installed-p 'nerd-icons)
  :ensure nil
  :demand t)

(provide 'loomacs-nerd-icons)
;;; loomacs-nerd-icons.el ends here
