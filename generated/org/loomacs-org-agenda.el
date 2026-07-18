;;; loomacs-org-agenda.el --- Loomacs Org Agenda -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(eval-when-compile (require 'use-package))

(defvar loomacs-org-directory)
(defvar org-agenda-files)
(defvar org-agenda-window-setup)
(defvar org-agenda-restore-windows-after-quit)

(defun loomacs-org-agenda ()
  "在用户主动调用时准备 Org 目录并打开 Agenda。"
  (interactive)
  ;; 与 Capture 一样，目录创建属于明确用户动作；普通 Emacs 启动不写 Documents。
  (make-directory loomacs-org-directory t)
  (setq org-agenda-files (list loomacs-org-directory))
  (call-interactively #'org-agenda))

(use-package org-agenda
  :ensure nil
  :commands org-agenda
  :bind (("C-c a" . loomacs-org-agenda))
  :init
  ;; Org 原生支持把目录作为 agenda 项；目录不存在时使用空列表，启动不产生文档。
  (setq org-agenda-files
        (when (file-directory-p loomacs-org-directory)
          (list loomacs-org-directory))
        org-agenda-window-setup 'current-window
        org-agenda-restore-windows-after-quit t))

(provide 'loomacs-org-agenda)
;;; loomacs-org-agenda.el ends here
