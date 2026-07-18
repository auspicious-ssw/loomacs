;;; loomacs-xref.el --- 原生代码跳转 -*- lexical-binding: t; -*-

(use-package xref
  :ensure nil
  :commands (xref-find-definitions xref-find-references xref-go-back xref-go-forward)
  :init
  (setq xref-search-program (if (executable-find "rg") 'ripgrep 'grep)))

(provide 'loomacs-xref)
;;; loomacs-xref.el ends here
