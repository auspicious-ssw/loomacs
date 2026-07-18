;;; loomacs-completion.el --- Loomacs 补全领域 -*- lexical-binding: t; -*-

(defgroup loomacs-completion nil
  "Loomacs 标准补全体系。"
  :group 'loomacs)

(defconst loomacs-completion-modules
  '(loomacs-vertico
    loomacs-orderless
    loomacs-marginalia
    loomacs-consult
    loomacs-embark
    loomacs-embark-consult
    loomacs-corfu
    loomacs-cape)
  "Completion 领域子模块的确定性加载顺序。")

(defconst loomacs-completion-packages
  '(vertico orderless marginalia consult embark embark-consult corfu cape)
  "Completion 领域需要显式安装的直接第三方包。")

(declare-function loomacs-register-packages "loomacs")

;; 注册只更新 package-selected-packages 声明，不刷新索引、不安装包；依赖安装仍是
;; 用户显式维护动作，离线启动契约不因此改变。
(when (fboundp 'loomacs-register-packages)
  (apply #'loomacs-register-packages loomacs-completion-packages))

;; TAB 仍先执行缩进，仅在当前模式提供 completion-at-point 时进入补全。
;; 这里不替换 Emacs 原生命令，只统一大小写与少量候选时的循环行为。
(setq tab-always-indent 'complete
      completion-cycle-threshold 3
      completion-ignore-case t
      read-buffer-completion-ignore-case t
      read-file-name-completion-ignore-case t
      enable-recursive-minibuffers t)

(provide 'loomacs-completion)
;;; loomacs-completion.el ends here
