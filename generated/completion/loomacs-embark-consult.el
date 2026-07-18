;;; loomacs-embark-consult.el --- Embark 与 Consult 集成 -*- lexical-binding: t; -*-

(declare-function consult-preview-at-point-mode "consult")

(use-package embark-consult
  :if (package-installed-p 'embark-consult)
  :ensure nil
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(provide 'loomacs-embark-consult)
;;; loomacs-embark-consult.el ends here
