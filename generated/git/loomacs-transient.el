;;; loomacs-transient.el --- Loomacs Transient 状态 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(eval-when-compile (require 'use-package))

(defvar loomacs-editor-state-directory)
(defvar transient-levels-file)
(defvar transient-values-file)
(defvar transient-history-file)

(defconst loomacs-transient-state-directory
  (file-name-as-directory
   (expand-file-name "transient" loomacs-editor-state-directory))
  "Transient 本机持久状态目录。")

(make-directory loomacs-transient-state-directory t)
(set-file-modes loomacs-transient-state-directory #o700)

(setq transient-levels-file
      (expand-file-name "levels.el" loomacs-transient-state-directory)
      transient-values-file
      (expand-file-name "values.el" loomacs-transient-state-directory)
      transient-history-file
      (expand-file-name "history.el" loomacs-transient-state-directory))

(use-package transient
  :ensure nil
  :commands (transient-setup transient-quit-one))

(provide 'loomacs-transient)
;;; loomacs-transient.el ends here
