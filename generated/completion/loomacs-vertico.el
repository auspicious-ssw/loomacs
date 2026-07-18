;;; loomacs-vertico.el --- Vertico 候选界面 -*- lexical-binding: t; -*-

(declare-function vertico-mode "vertico")

(use-package vertico
  :if (package-installed-p 'vertico)
  :ensure nil
  :init
  (setq vertico-count 12
        vertico-cycle t
        vertico-resize t)
  (vertico-mode 1))

(provide 'loomacs-vertico)
;;; loomacs-vertico.el ends here
