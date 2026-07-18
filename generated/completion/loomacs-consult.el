;;; loomacs-consult.el --- Consult 搜索入口 -*- lexical-binding: t; -*-

;; keymap 在 Consult 首次加载前存在；显式声明公共命令可保持延迟加载并让每个
;; 生成模块在第三方 feature 未预载时仍可独立严格编译。
(declare-function consult-buffer "consult")
(declare-function consult-find "consult")
(declare-function consult-ripgrep "consult")
(declare-function consult-history "consult")
(declare-function consult-imenu "consult")
(declare-function consult-line "consult")
(declare-function consult-mark "consult")
(declare-function consult-outline "consult")
(declare-function consult-yank-pop "consult")

(defvar-keymap loomacs-consult-map
  :doc "Loomacs 搜索命令。"
  "b" #'consult-buffer
  "f" #'consult-find
  "g" #'consult-ripgrep
  "h" #'consult-history
  "i" #'consult-imenu
  "l" #'consult-line
  "m" #'consult-mark
  "o" #'consult-outline
  "y" #'consult-yank-pop)

(when (package-installed-p 'consult)
  (keymap-global-set "C-c s" loomacs-consult-map))

(use-package consult
  :if (package-installed-p 'consult)
  :ensure nil
  :commands (consult-buffer consult-find consult-ripgrep consult-history
                            consult-imenu consult-line consult-mark consult-outline
                            consult-yank-pop))

(provide 'loomacs-consult)
;;; loomacs-consult.el ends here
