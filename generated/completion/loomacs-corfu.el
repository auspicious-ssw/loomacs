;;; loomacs-corfu.el --- 编辑区悬浮补全 -*- lexical-binding: t; -*-

(declare-function global-corfu-mode "corfu")
(declare-function corfu-history-mode "corfu-history")
(declare-function corfu-popupinfo-mode "corfu-popupinfo")

(use-package corfu
  :if (package-installed-p 'corfu)
  :ensure nil
  :defines (corfu-history corfu-popupinfo-delay savehist-additional-variables)
  :init
  ;; 自动补全可能调用来自文件/模式的 CAPF。默认手动触发可避免仅打开不可信文件
  ;; 就执行补全后端，同时仍让所有标准 completion-at-point 来源共享同一个 UI。
  (setq corfu-auto nil
        corfu-cycle t
        corfu-on-exact-match nil
        corfu-preselect 'prompt
        corfu-preview-current nil
        global-corfu-minibuffer nil)
  (global-corfu-mode 1)
  :config
  (corfu-history-mode 1)
  (corfu-popupinfo-mode 1)
  (setq corfu-popupinfo-delay '(0.5 . 0.2))
  (with-eval-after-load 'savehist
    (add-to-list 'savehist-additional-variables 'corfu-history)))

(provide 'loomacs-corfu)
;;; loomacs-corfu.el ends here
