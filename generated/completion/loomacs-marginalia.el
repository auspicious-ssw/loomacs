;;; loomacs-marginalia.el --- 候选注释 -*- lexical-binding: t; -*-

(declare-function marginalia-mode "marginalia")

(use-package marginalia
  :if (package-installed-p 'marginalia)
  :ensure nil
  :init
  (marginalia-mode 1))

(provide 'loomacs-marginalia)
;;; loomacs-marginalia.el ends here
