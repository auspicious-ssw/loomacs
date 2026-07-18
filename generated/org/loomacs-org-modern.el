;;; loomacs-org-modern.el --- Loomacs Org Modern -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(eval-when-compile (require 'use-package))

(use-package org-modern
  :if (package-installed-p 'org-modern)
  :ensure nil
  :after org
  :hook (org-mode . org-modern-mode)
  :init
  (setq org-modern-star 'fold
        org-modern-hide-stars 'leading
        org-modern-label-border 0.12
        org-modern-table-vertical 1
        org-modern-table-horizontal 0.10
        org-modern-block-fringe 3)
  :config
  ;; 结构符号继续使用已验证等宽字体，避免与中文回退字体基线漂移。
  (when (and (boundp 'loomacs-font-family)
             (find-font (font-spec :family loomacs-font-family)))
    (set-face-attribute 'org-modern-symbol nil :family loomacs-font-family)))

(provide 'loomacs-org-modern)
;;; loomacs-org-modern.el ends here
