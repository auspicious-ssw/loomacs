;;; loomacs-org-appear.el --- Loomacs Org Appear -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(eval-when-compile (require 'use-package))

(use-package org-appear
  :if (package-installed-p 'org-appear)
  :ensure nil
  :after org
  :hook (org-mode . org-appear-mode)
  :init
  (setq org-appear-trigger 'always
        org-appear-delay 0
        org-appear-autoemphasis t
        org-appear-autolinks t
        org-appear-autosubmarkers t
        org-appear-autoentities t
        org-appear-inside-latex t))

(provide 'loomacs-org-appear)
;;; loomacs-org-appear.el ends here
