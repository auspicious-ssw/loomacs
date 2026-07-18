;;; loomacs-input-source.el --- Loomacs macOS 输入源 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(eval-when-compile (require 'use-package))

(defvar sis-external-ism)
(declare-function sis-set-english "sis" ())
(declare-function sis-ism-lazyman-config "sis"
                  (english-source other-source &optional ism-type))

(defconst loomacs-macism-executable
  (when (fboundp 'loomacs-macos-find-executable)
    (loomacs-macos-find-executable "macism"))
  "当前可用的 macism 绝对路径；不可用时为 nil。")

(defun loomacs-select-english-input-source (&optional frame)
  "当 FRAME 是顶层 GUI frame 时，将 macOS 输入源切到英文。"
  (let ((target-frame (or frame (selected-frame))))
    (when (frame-live-p target-frame)
      (with-selected-frame target-frame
        ;; 只在工作 frame 创建时执行一次，避免编辑期间抢回英文。
        (when (and (display-graphic-p)
                   (not (frame-parent))
                   (fboundp 'sis-set-english))
          (sis-set-english))))))

(use-package sis
  :if (and (eq system-type 'darwin)
           (package-installed-p 'sis)
           loomacs-macism-executable)
  :ensure nil
  :demand t
  :config
  (sis-ism-lazyman-config
   "com.apple.keylayout.ABC"
   "com.apple.inputmethod.SCIM.ITABC"
   'macism)
  ;; Finder 启动的 GUI 环境可能没有 Homebrew PATH，因此使用已验证绝对路径。
  (setq sis-external-ism loomacs-macism-executable)
  (add-hook 'emacs-startup-hook #'loomacs-select-english-input-source)
  (add-hook 'after-make-frame-functions #'loomacs-select-english-input-source))

(provide 'loomacs-input-source)
;;; loomacs-input-source.el ends here
