;;; loomacs-eglot.el --- 内置 Eglot 配置 -*- lexical-binding: t; -*-

(require 'seq)

(declare-function eglot-ensure "eglot")

(defcustom loomacs-eglot-auto-start t
  "非 nil 时，仅在本地项目且检测到对应 server 时自动启动 Eglot。"
  :type 'boolean
  :group 'loomacs-lsp)

(defconst loomacs-eglot-mode-server-candidates
  '((python-mode "basedpyright-langserver" "pyright-langserver" "pylsp" "jedi-language-server")
    (python-ts-mode "basedpyright-langserver" "pyright-langserver" "pylsp" "jedi-language-server")
    (js-mode "typescript-language-server")
    (js-ts-mode "typescript-language-server")
    (typescript-mode "typescript-language-server")
    (typescript-ts-mode "typescript-language-server")
    (tsx-ts-mode "typescript-language-server")
    (json-mode "vscode-json-language-server" "vscode-json-languageserver")
    (json-ts-mode "vscode-json-language-server" "vscode-json-languageserver")
    (css-mode "vscode-css-language-server" "css-languageserver")
    (css-ts-mode "vscode-css-language-server" "css-languageserver")
    (html-mode "vscode-html-language-server" "html-languageserver"))
  "允许自动启动 Eglot 的 major mode 与 server 候选。")

(defun loomacs-eglot--server-available-p ()
  "当前 major mode 至少存在一个已声明 server 时返回非 nil。"
  (when-let ((commands (cdr (assq major-mode loomacs-eglot-mode-server-candidates))))
    (seq-some #'executable-find commands)))

(defun loomacs-eglot-maybe-ensure ()
  "满足本地文件、项目和 server 三个条件时启动 Eglot。"
  ;; 不为临时 buffer、远程文件或未知项目创建外部进程；这既避免无意义报错，
  ;; 也阻止仅访问远端/陌生文件就隐式启动本机 language server。
  (when (and loomacs-eglot-auto-start
             buffer-file-name
             (not (file-remote-p buffer-file-name))
             (project-current nil)
             (loomacs-eglot--server-available-p))
    (eglot-ensure)))

(use-package eglot
  :ensure nil
  :commands (eglot eglot-ensure eglot-code-actions eglot-rename eglot-format
                   eglot-code-action-organize-imports eglot-reconnect eglot-shutdown)
  :init
  ;; 最后一个受管 buffer 关闭后释放 server；连接最多同步等待一秒，随后转后台。
  (setq eglot-autoshutdown t
        eglot-sync-connect 1
        eglot-connect-timeout 30))

(add-hook 'prog-mode-hook #'loomacs-eglot-maybe-ensure 80)

(provide 'loomacs-eglot)
;;; loomacs-eglot.el ends here
