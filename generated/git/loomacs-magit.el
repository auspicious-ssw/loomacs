;;; loomacs-magit.el --- Loomacs Magit -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(eval-when-compile
  (require 'use-package)
  (require 'project))

(declare-function magit-display-buffer-same-window-except-diff-v1 "magit-mode")
(declare-function magit-restore-window-configuration "magit-mode")

(use-package magit
  :if (package-installed-p 'magit)
  :ensure nil
  :commands (magit-status
             magit-dispatch
             magit-file-dispatch
             magit-project-status)
  :bind (("C-x g" . magit-status)
         ("C-c g" . magit-dispatch)
         ("C-c f" . magit-file-dispatch))
  :init
  (setq magit-display-buffer-function
        #'magit-display-buffer-same-window-except-diff-v1
        magit-bury-buffer-function #'magit-restore-window-configuration
        ;; 仅对已访问 hunk 细化词级差异，避免大型 diff 一次性展开导致停顿。
        magit-diff-refine-hunk t
        magit-save-repository-buffers t
        magit-no-confirm nil
        magit-repository-directories '(("~/Projects/" . 2)
                                       ("~/.config/" . 1))
        magit-clone-default-directory "~/Projects/")
  ;; 复用 project.el 的项目边界，不维护第二份项目数据库。
  (with-eval-after-load 'project
    (keymap-set project-prefix-map "m" #'magit-project-status)
    (add-to-list 'project-switch-commands
                 '(magit-project-status "Magit") t)))

(provide 'loomacs-magit)
;;; loomacs-magit.el ends here
