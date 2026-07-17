;;; early-init.el --- Emacs 启动阶段配置 -*- lexical-binding: t; -*-

(defconst ssw/gc-cons-threshold-normal (* 16 1024 1024)
  "Emacs 进入交互阶段后的 GC 内存阈值。")

(defconst ssw/gc-cons-percentage-normal 0.1
  "Emacs 进入交互阶段后的 GC 比例阈值。")

(defun ssw/restore-gc-settings ()
  "恢复适合交互使用的 GC 参数。"
  (setq gc-cons-threshold ssw/gc-cons-threshold-normal
        gc-cons-percentage ssw/gc-cons-percentage-normal))

;; 启动时暂时放宽 GC，减少初始化停顿。恢复函数在 early-init 阶段注册，
;; 即使 init.el 中途出错，正常完成的启动流程仍会把 GC 恢复到安全值。
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6
      package-enable-at-startup nil)
(add-hook 'emacs-startup-hook #'ssw/restore-gc-settings)

;; 在窗口创建前关闭不需要的界面元素，避免启动时闪烁。
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(provide 'early-init)
;;; early-init.el ends here
