;;; loomacs-project.el --- Loomacs project.el -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(eval-when-compile (require 'use-package))

(use-package project
  :ensure nil
  :commands (project-current
             project-find-file
             project-switch-project
             project-remember-projects-under))

(provide 'loomacs-project)
;;; loomacs-project.el ends here
