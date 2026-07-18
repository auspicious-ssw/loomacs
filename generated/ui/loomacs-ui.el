;;; loomacs-ui.el --- Loomacs UI 领域 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(declare-function loomacs-register-packages "loomacs-packages" (&rest packages))

(defconst loomacs-ui-modules
  '(loomacs-batppuccin
    loomacs-nerd-icons
    loomacs-dashboard
    loomacs-doom-modeline)
  "UI 领域的有序子模块 feature 清单。")

(defconst loomacs-ui-packages
  '(batppuccin dashboard doom-modeline nerd-icons)
  "UI 领域直接使用的第三方包。")

(apply #'loomacs-register-packages loomacs-ui-packages)

(provide 'loomacs-ui)
;;; loomacs-ui.el ends here
