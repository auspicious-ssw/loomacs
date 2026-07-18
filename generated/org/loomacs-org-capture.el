;;; loomacs-org-capture.el --- Loomacs Org Capture -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(eval-when-compile (require 'use-package))

(defvar loomacs-org-directory)

(defconst loomacs-org-capture-task-file
  (expand-file-name "tasks.org" loomacs-org-directory)
  "Loomacs Capture 任务入口文件。")

(defconst loomacs-org-capture-note-file
  (expand-file-name "notes.org" loomacs-org-directory)
  "Loomacs Capture 笔记入口文件。")

(defun loomacs-org-capture ()
  "在用户主动调用时确保 Org 目录存在，然后打开 Capture。"
  (interactive)
  ;; 延迟创建目录是明确用户动作，避免仅启动 Emacs 就修改 Documents。
  (make-directory loomacs-org-directory t)
  (call-interactively #'org-capture))

(use-package org-capture
  :ensure nil
  :commands org-capture
  :bind (("C-c c" . loomacs-org-capture))
  :init
  (setq org-capture-templates
        `(("t" "Task" entry
           (file ,loomacs-org-capture-task-file)
           "* TODO %?\n  %U\n" :empty-lines 1)
          ("n" "Note" entry
           (file ,loomacs-org-capture-note-file)
           "* %?\n  %U\n" :empty-lines 1))))

(provide 'loomacs-org-capture)
;;; loomacs-org-capture.el ends here
