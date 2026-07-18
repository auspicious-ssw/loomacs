;;; loomacs-font.el --- Loomacs macOS 字体 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

;; 字体参数由 Profile 唯一持有；无初值声明只建立独立编译契约，不覆盖 Profile。
(defvar loomacs-font-family)
(defvar loomacs-font-height)
(defvar loomacs-cjk-font-family)
(declare-function set-fontset-font "fontset"
                  (fontset characters font-spec &optional frame add))

(defun loomacs-apply-fonts (&optional frame)
  "为 FRAME 应用 Loomacs 代码字体和中文回退字体。"
  (let ((target-frame (or frame (selected-frame))))
    (when (frame-live-p target-frame)
      (with-selected-frame target-frame
        (when (find-font (font-spec :family loomacs-font-family))
          (set-face-attribute 'default target-frame
                              :family loomacs-font-family
                              :height loomacs-font-height
                              :weight 'regular))
        ;; `t' 只修改默认 fontset，已经创建的 NS frame 不会自动继承。必须同时
        ;; 更新当前 GUI frame；TTY/batch 没有 fontset，不能调用该 API。
        (when (display-graphic-p target-frame)
          (let ((cjk-font (font-spec :family loomacs-cjk-font-family)))
            (set-fontset-font t 'han cjk-font nil 'prepend)
            (set-fontset-font nil 'han cjk-font target-frame 'prepend)))))))

(loomacs-apply-fonts)
(add-hook 'after-make-frame-functions #'loomacs-apply-fonts)

(provide 'loomacs-font)
;;; loomacs-font.el ends here
