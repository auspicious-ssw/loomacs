;;; loomacs-transient-posframe.el --- Loomacs Transient Posframe -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(eval-when-compile (require 'use-package))

(declare-function batppuccin-get-color "batppuccin" (name flavor))
(declare-function posframe-poshandler-window-center "posframe" (info))
(declare-function posframe-workable-p "posframe" ())
(declare-function transient-posframe-mode "transient-posframe" (&optional arg))

(defun loomacs-transient-posframe--sync (&rest _)
  "根据当前 frame 是否支持 child-frame，同步悬浮菜单模式。"
  (let ((workable (posframe-workable-p)))
    (cond
     ((and workable (not transient-posframe-mode))
      (transient-posframe-mode 1))
     ((and (not workable) transient-posframe-mode)
      (transient-posframe-mode -1)))))

(use-package transient-posframe
  :if (package-installed-p 'transient-posframe)
  :ensure nil
  :after transient
  :init
  (setq transient-posframe-font nil
        transient-posframe-poshandler #'posframe-poshandler-window-center
        transient-posframe-border-width 2
        transient-posframe-parameters '((left-fringe . 14)
                                        (right-fringe . 14))
        transient-minimal-frame-width 84)
  :config
  ;; 只使用 Batppuccin 的公开 palette API，避免复制 Transient 已有 face 配色。
  (when (and (featurep 'batppuccin)
             (memq 'batppuccin-mocha custom-enabled-themes))
    (set-face-attribute
     'transient-posframe nil
     :foreground (batppuccin-get-color "bat-text" 'batppuccin-mocha)
     :background (batppuccin-get-color "bat-mantle" 'batppuccin-mocha))
    (set-face-attribute
     'transient-posframe-border nil
     :background (batppuccin-get-color "bat-mauve" 'batppuccin-mocha)))
  (unless (advice-member-p #'loomacs-transient-posframe--sync 'transient-setup)
    (advice-add 'transient-setup :before #'loomacs-transient-posframe--sync)))

(provide 'loomacs-transient-posframe)
;;; loomacs-transient-posframe.el ends here
