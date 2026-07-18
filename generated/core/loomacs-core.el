;;; loomacs-core.el --- Loomacs Core 领域 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(defconst loomacs-core-modules
  '(loomacs-startup
    loomacs-state
    loomacs-packages
    loomacs-editing)
  "Core 领域的有序子模块 feature 清单。")

(defun loomacs-core-finalize-startup ()
  "在 Loomacs 模块全部加载后恢复交互阶段 GC 参数。"
  ;; early-init 也会在 emacs-startup-hook 中执行同一恢复。这里的
  ;; 显式收尾用于手工加载以及启动链未经过正常 hook 的场景。
  (when (fboundp 'loomacs-restore-gc-settings)
    (loomacs-restore-gc-settings)))

(provide 'loomacs-core)
;;; loomacs-core.el ends here
