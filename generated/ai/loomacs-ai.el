;;; loomacs-ai.el --- Loomacs AI 领域 -*- lexical-binding: t; -*-

(defgroup loomacs-ai nil
  "Loomacs 中由用户显式触发的 AI 工作流。"
  :group 'loomacs)

(defconst loomacs-ai-modules
  '(loomacs-auth-source loomacs-gptel)
  "AI 领域子模块的确定性加载顺序。")

(defconst loomacs-ai-packages '(gptel)
  "AI 领域需要显式安装的直接第三方包。")

;; 这里只声明可由 package.el 显式维护的依赖；不会在启动阶段读取包索引或联网。
(when (fboundp 'loomacs-register-packages)
  (apply #'loomacs-register-packages loomacs-ai-packages))

(defconst loomacs-ai-network-policy 'explicit-command
  "AI 网络请求只能由用户调用 gptel 命令触发。")

;; AI 入口先于 gptel 延迟加载建立 keymap；这些声明只提供静态编译契约，
;; 不 require gptel，也不会在启动时读取凭据或产生网络请求。
(declare-function loomacs-register-packages "loomacs")
(declare-function gptel "gptel")
(declare-function gptel-add "gptel")
(declare-function gptel-add-file "gptel")
(declare-function gptel-menu "gptel")
(declare-function gptel-rewrite "gptel")
(declare-function gptel-send "gptel")

(defvar-keymap loomacs-ai-map
  :doc "Loomacs AI 命令。"
  "a" #'gptel-add
  "c" #'gptel
  "f" #'gptel-add-file
  "m" #'gptel-menu
  "r" #'gptel-rewrite
  "s" #'gptel-send)

(when (package-installed-p 'gptel)
  ;; C-c i 属于用户保留空间，不占用 Org 的 C-c l 或 Emacs 的 C-g。
  (keymap-global-set "C-c i" loomacs-ai-map))

(provide 'loomacs-ai)
;;; loomacs-ai.el ends here
