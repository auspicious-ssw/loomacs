;;; loomacs-gui-validation.el --- Loomacs macOS GUI 真实验收 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>
;; Package-Requires: ((emacs "30.2"))

;;; Commentary:

;; 该脚本只供独立 GUI Emacs 验收使用，不属于正常启动或 batch ERT。调用
;; `loomacs-gui-validation-run' 后，它会在启动完成两秒后检查真实 frame、Dashboard、
;; 字体、输入源、Corfu child-frame 和 Transient Posframe，把 plist 写到环境变量
;; LOOMACS_GUI_RESULT 指定路径，然后退出该独立验证进程。

;;; Code:

(require 'cl-lib)

(defvar corfu--frame)
(defvar doom-modeline-mode)
(defvar global-corfu-mode)
(defvar loomacs-active-profile)
(defvar loomacs-loaded-modules)
(defvar transient--buffer-name)
(defvar transient-posframe-mode)

(declare-function corfu-quit "corfu" ())
(declare-function fontset-font "fontset" (name ch &optional all))
(declare-function magit-dispatch "magit" ())
(declare-function posframe-workable-p "posframe" ())
(declare-function transient-quit-one "transient" ())

(defun loomacs-gui-validation--write (result)
  "把 RESULT 写到验证结果文件。"
  (let ((file (getenv "LOOMACS_GUI_RESULT")))
    (unless file
      (error "缺少 LOOMACS_GUI_RESULT"))
    (with-temp-file file
      (prin1 result (current-buffer))
      (insert "\n"))))

(defun loomacs-gui-validation--child-frame-p (frame)
  "FRAME 是挂在正常工作 frame 下的 child-frame 时返回非 nil。"
  (and (frame-live-p frame)
       (frame-parent frame)))

(defun loomacs-gui-validation--worker ()
  "执行真实 GUI 验收，记录结果后退出独立 Emacs。"
  (let (result)
    (condition-case error-data
        (let* ((frame (selected-frame))
               (initial-buffer (buffer-name (window-buffer (selected-window))))
               (window-id (frame-parameter frame 'outer-window-id))
               (screenshot (getenv "LOOMACS_GUI_SCREENSHOT"))
               (input-source
                (when (file-executable-p "/opt/homebrew/bin/macism")
                  (car (process-lines "/opt/homebrew/bin/macism"))))
               cjk-family fontset-current fontset-default
               corfu-child transient-child)
          (unless (display-graphic-p frame)
            (error "验证进程不是图形 frame"))
          (select-frame-set-input-focus frame)
          (redisplay t)
          (when (and screenshot
                     (file-executable-p "/usr/sbin/screencapture"))
            (if window-id
                (call-process "/usr/sbin/screencapture" nil nil nil
                              "-x" "-l" (format "%s" window-id) screenshot)
              (pcase-let ((`(,x . ,y) (frame-position frame)))
                (call-process
                 "/usr/sbin/screencapture" nil nil nil "-x" "-R"
                 (format "%d,%d,%d,%d" x y
                         (frame-pixel-width frame) (frame-pixel-height frame))
                 screenshot))))

          ;; 在真实窗口中显示一个中文字形，确认 macOS 字体回退实际生效。
          (with-current-buffer (get-buffer-create " *loomacs-gui-font*")
            (erase-buffer)
            (insert "中")
            (set-window-buffer (selected-window) (current-buffer))
            (redisplay t)
            (when-let ((font (font-at (point-min) (selected-window))))
              (setq cjk-family (font-get font :family)))
            (setq fontset-current (fontset-font nil ?中 t)
                  fontset-default (fontset-font t ?中 t)))

          ;; Corfu 只在用户显式 completion-at-point 时弹出；这里模拟一次 TAB 语义。
          (with-current-buffer (get-buffer-create "*loomacs-gui-corfu*")
            (erase-buffer)
            (emacs-lisp-mode)
            (insert "(mess")
            (set-window-buffer (selected-window) (current-buffer))
            (goto-char (point-max))
            (completion-at-point)
            (run-hooks 'post-command-hook)
            (redisplay t)
            (sit-for 0.2)
            (setq corfu-child
                  (loomacs-gui-validation--child-frame-p corfu--frame))
            (when (fboundp 'corfu-quit)
              (corfu-quit)))

          ;; Magit Dispatch 必须通过 Transient Posframe 显示；Status 本身仍是普通窗口。
          (let ((default-directory user-emacs-directory))
            (call-interactively #'magit-dispatch)
            (redisplay t)
            (sit-for 0.2)
            (let ((window (get-buffer-window transient--buffer-name t)))
              (setq transient-child
                    (and window
                         (loomacs-gui-validation--child-frame-p
                          (window-frame window)))))
            (when (fboundp 'transient-quit-one)
              (transient-quit-one)))

          (setq result
                `(:graphic t
                  :fullscreen ,(frame-parameter frame 'fullscreen)
                  :pixel-size (,(frame-pixel-width frame)
                               ,(frame-pixel-height frame))
                  :font-family ,(face-attribute 'default :family frame t)
                  :font-height ,(face-attribute 'default :height frame t)
                  :cjk-family ,cjk-family
                  :fontset-current ,fontset-current
                  :fontset-default ,fontset-default
                  :initial-buffer ,initial-buffer
                  :theme ,custom-enabled-themes
                  :dashboard ,(featurep 'dashboard)
                  :doom-modeline ,(bound-and-true-p doom-modeline-mode)
                  :corfu ,(bound-and-true-p global-corfu-mode)
                  :corfu-child-frame ,(and corfu-child t)
                  :posframe-workable ,(and (fboundp 'posframe-workable-p)
                                           (posframe-workable-p))
                  :transient-posframe ,(and (boundp 'transient-posframe-mode)
                                             transient-posframe-mode)
                  :transient-child-frame ,(and transient-child t)
                  :input-source ,input-source
                  :modules ,(length loomacs-loaded-modules)
                  :profile ,loomacs-active-profile)))
      (error
       (setq result `(:error ,(error-message-string error-data)))))
    (loomacs-gui-validation--write result)
    (kill-emacs (if (plist-get result :error) 1 0))))

(defun loomacs-gui-validation-run ()
  "安排一次独立 GUI Loomacs 真实验收。"
  (interactive)
  (run-at-time 2 nil #'loomacs-gui-validation--worker))

(provide 'loomacs-gui-validation)
;;; loomacs-gui-validation.el ends here
