;;; loomacs-orderless.el --- Orderless 匹配策略 -*- lexical-binding: t; -*-

(use-package orderless
  :if (package-installed-p 'orderless)
  :ensure nil
  :init
  ;; basic 是动态 completion table 的兼容兜底；文件类别单独保留路径通配与缩写。
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion basic)))))

(provide 'loomacs-orderless)
;;; loomacs-orderless.el ends here
