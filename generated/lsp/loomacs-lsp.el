;;; loomacs-lsp.el --- Loomacs 代码智能领域 -*- lexical-binding: t; -*-

(defgroup loomacs-lsp nil
  "Loomacs 内置代码智能配置。"
  :group 'loomacs)

(defconst loomacs-lsp-modules
  '(loomacs-eglot loomacs-xref loomacs-flymake loomacs-treesit)
  "LSP 领域子模块的确定性加载顺序。")

(defconst loomacs-lsp-packages nil
  "LSP 领域的直接第三方 Emacs 包；当前全部使用 Emacs 30 内置能力。")

(defconst loomacs-lsp-external-tools
  '((python "basedpyright-langserver" "pyright-langserver")
    (javascript "typescript-language-server")
    (json "vscode-json-language-server" "vscode-json-languageserver")
    (css "vscode-css-language-server" "css-languageserver")
    (html "vscode-html-language-server" "html-languageserver")
    (markdown "marksman" "vscode-markdown-language-server"))
  "Doctor 可检查的可选语言服务器候选；Loomacs 不负责安装它们。")

;; 这两个命令由后续 Tree-sitter 子模块提供；显式声明跨模块公共契约，避免
;; byte compiler 把确定性的 Manifest 加载顺序误报为未定义函数。
(declare-function loomacs-treesit-install-language "loomacs-treesit")
(declare-function loomacs-treesit-remap-installed-modes "loomacs-treesit")
(declare-function eglot "eglot")
(declare-function eglot-code-actions "eglot")
(declare-function eglot-code-action-organize-imports "eglot")
(declare-function eglot-format "eglot")
(declare-function eglot-reconnect "eglot")
(declare-function eglot-rename "eglot")
(declare-function eglot-shutdown "eglot")
(declare-function flymake-show-project-diagnostics "flymake")
(declare-function flymake-show-buffer-diagnostics "flymake")
(declare-function flymake-goto-next-error "flymake")
(declare-function flymake-goto-prev-error "flymake")

(defvar-keymap loomacs-diagnostics-map
  :doc "Loomacs 诊断命令。"
  "a" #'flymake-show-project-diagnostics
  "b" #'flymake-show-buffer-diagnostics
  "n" #'flymake-goto-next-error
  "p" #'flymake-goto-prev-error)

(defvar-keymap loomacs-lsp-map
  :doc "Loomacs LSP 与语法树命令。"
  "R" #'eglot-reconnect
  "T" #'loomacs-treesit-remap-installed-modes
  "a" #'eglot-code-actions
  "d" loomacs-diagnostics-map
  "e" #'eglot
  "f" #'eglot-format
  "i" #'eglot-code-action-organize-imports
  "q" #'eglot-shutdown
  "r" #'eglot-rename
  "t" #'loomacs-treesit-install-language)

;; C-c 加小写字母是 Emacs 明确保留给用户的空间；不改 C-g、M-. 或方向键。
(keymap-global-set "C-c e" loomacs-lsp-map)

(provide 'loomacs-lsp)
;;; loomacs-lsp.el ends here
