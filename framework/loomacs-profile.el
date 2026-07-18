;;; loomacs-profile.el --- Loomacs Profile 元数据 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW
;; URL: https://github.com/auspicious-ssw/loomacs
;; Package-Requires: ((emacs "30.2"))

;;; Commentary:

;; Profile 本身也是 Manifest 中的普通模块。本文件只保存当前构建声明的
;; Profile 名称，避免为 Profile 发明另一套加载机制。

;;; Code:

(require 'loomacs)

(defvar loomacs-active-profile nil
  "当前 Manifest 声明的 Profile；没有声明时为 nil。")

(defun loomacs-profile-activate (manifest)
  "从 MANIFEST 激活并返回 Profile 名称。"
  (let ((profile (plist-get manifest :profile)))
    (unless (or (null profile) (symbolp profile))
      (error "Manifest 的 :profile 必须是 symbol 或 nil：%S" profile))
    (setq loomacs-active-profile profile)))

(provide 'loomacs-profile)
;;; loomacs-profile.el ends here
