;;; loomacs-flymake.el --- 内置实时诊断 -*- lexical-binding: t; -*-

(declare-function flymake-mode "flymake")

(use-package flymake
  :ensure nil
  :commands (flymake-mode flymake-show-buffer-diagnostics
                          flymake-show-project-diagnostics
                          flymake-goto-next-error flymake-goto-prev-error)
  :init
  (setq flymake-no-changes-timeout 0.5
        flymake-suppress-zero-counters t))

(provide 'loomacs-flymake)
;;; loomacs-flymake.el ends here
