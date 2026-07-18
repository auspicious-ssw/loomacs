;;; loomacs-git.el --- Loomacs Git 领域 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(declare-function loomacs-register-packages "loomacs-packages" (&rest packages))

(defconst loomacs-git-modules
  '(loomacs-transient
    loomacs-magit
    loomacs-transient-posframe)
  "Git 领域的有序子模块 feature 清单。")

(defconst loomacs-git-packages
  '(magit transient transient-posframe)
  "Git 领域直接使用的第三方包。")

(apply #'loomacs-register-packages loomacs-git-packages)

(provide 'loomacs-git)
;;; loomacs-git.el ends here
