;;; loomacs-embark.el --- Embark 对象操作 -*- lexical-binding: t; -*-

(declare-function embark-act "embark")
(declare-function embark-bindings "embark")
(declare-function embark-collect "embark")
(declare-function embark-dwim "embark")
(declare-function embark-export "embark")

(defvar-keymap loomacs-embark-map
  :doc "Loomacs 对象操作命令。"
  "a" #'embark-act
  "b" #'embark-bindings
  "c" #'embark-collect
  "d" #'embark-dwim
  "e" #'embark-export)

(when (package-installed-p 'embark)
  (keymap-global-set "C-c o" loomacs-embark-map))

(use-package embark
  :if (package-installed-p 'embark)
  :ensure nil
  :commands (embark-act embark-bindings embark-collect embark-dwim embark-export))

(provide 'loomacs-embark)
;;; loomacs-embark.el ends here
