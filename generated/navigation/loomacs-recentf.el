;;; loomacs-recentf.el --- Loomacs 最近文件 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(eval-when-compile (require 'use-package))

(require 'seq)

(defvar loomacs-state-root)
(defvar loomacs-cache-root)
(defvar loomacs-legacy-state-root)
(defvar recentf-exclude)
(declare-function recentf-cleanup "recentf" ())

(defun loomacs-recentf--runtime-file-p (file)
  "FILE 位于 Loomacs 当前/旧状态或缓存目录时返回非 nil。"
  (let ((expanded (expand-file-name file)))
    (seq-some
     (lambda (root)
       (string-prefix-p (file-name-as-directory (expand-file-name root))
                        expanded))
     (list loomacs-state-root loomacs-cache-root loomacs-legacy-state-root))))

(use-package recentf
  :ensure nil
  :demand t
  :init
  (setq recentf-max-saved-items 100)
  :config
  (add-to-list 'recentf-exclude #'loomacs-recentf--runtime-file-p)
  (recentf-mode 1)
  (recentf-cleanup))

(provide 'loomacs-recentf)
;;; loomacs-recentf.el ends here
