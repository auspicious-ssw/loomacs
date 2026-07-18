;;; loomacs-cape.el --- Completion At Point 扩展 -*- lexical-binding: t; -*-

(declare-function cape-file "cape")
(declare-function cape-dabbrev "cape")
(declare-function cape-elisp-block "cape")

(defun loomacs-cape-setup-defaults ()
  "为当前 buffer 追加通用 Cape CAPF。"
  ;; append=t 保证语言模式或 Eglot 的语义补全优先，Cape 只在前置 CAPF 不适用时兜底。
  (add-hook 'completion-at-point-functions #'cape-file t t)
  (add-hook 'completion-at-point-functions #'cape-dabbrev t t))

(defun loomacs-cape-setup-org ()
  "为 Org buffer 增加源码块 Elisp 补全，并保留通用 CAPF。"
  ;; 源码块 CAPF 必须先于 dabbrev 兜底，否则普通词汇候选会提前结束 CAPF 链。
  (add-hook 'completion-at-point-functions #'cape-elisp-block nil t)
  (loomacs-cape-setup-defaults))

(when (package-installed-p 'cape)
  (add-hook 'prog-mode-hook #'loomacs-cape-setup-defaults)
  (add-hook 'text-mode-hook #'loomacs-cape-setup-defaults)
  (add-hook 'org-mode-hook #'loomacs-cape-setup-org))

(use-package cape
  :if (package-installed-p 'cape)
  :ensure nil
  :commands (cape-file cape-dabbrev cape-elisp-block))

(provide 'loomacs-cape)
;;; loomacs-cape.el ends here
