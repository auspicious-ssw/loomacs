;;; loomacs-editing.el --- Loomacs 基础编辑 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(delete-selection-mode 1)
(electric-pair-mode 1)
(global-auto-revert-mode 1)
(column-number-mode 1)
(show-paren-mode 1)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)

;; 统一使用 UTF-8，确保中文文件、剪贴板与终端内容不漂移。
(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8-unix)
(set-default-coding-systems 'utf-8-unix)

(provide 'loomacs-editing)
;;; loomacs-editing.el ends here
