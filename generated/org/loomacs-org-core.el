;;; loomacs-org-core.el --- Loomacs Org Core -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(eval-when-compile (require 'use-package))

(defun loomacs-org--visual-setup ()
  "为当前 Org buffer 应用轻量排版，不改变文档内容或按键。"
  (setq-local line-spacing 0.18)
  (visual-line-mode 1)
  ;; 使用相对 face 保留主题配色，只建立可读的标题层级。
  (face-remap-add-relative 'org-document-title '(:height 1.45 :weight bold))
  (face-remap-add-relative 'org-level-1 '(:height 1.30 :weight bold))
  (face-remap-add-relative 'org-level-2 '(:height 1.18 :weight bold))
  (face-remap-add-relative 'org-level-3 '(:height 1.10 :weight semi-bold))
  (face-remap-add-relative 'org-level-4 '(:height 1.04 :weight semi-bold)))

(use-package org
  :ensure nil
  :mode ("\\.org\\'" . org-mode)
  :bind (("C-c l" . org-store-link))
  :hook (org-mode . loomacs-org--visual-setup)
  :init
  (setq org-auto-align-tags nil
        org-tags-column 0
        org-fold-catch-invisible-edits 'show-and-error
        org-special-ctrl-a/e t
        org-insert-heading-respect-content t
        org-hide-emphasis-markers t
        org-pretty-entities t
        org-ellipsis "…"
        org-fontify-quote-and-verse-blocks t
        org-fontify-done-headline t))

(provide 'loomacs-org-core)
;;; loomacs-org-core.el ends here
