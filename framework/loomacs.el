;;; loomacs.el --- Loomacs 公共 API 与版本信息 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW
;; URL: https://github.com/auspicious-ssw/loomacs
;; Package-Requires: ((emacs "30.2"))
;; Keywords: convenience, literate, configuration

;;; Commentary:

;; Loomacs 是由 Org 源文件显式构建、由确定性 Manifest 离线加载的 Emacs
;; 配置框架。本文件只定义稳定的公共命名空间和版本，不承担启动副作用。

;;; Code:

(defgroup loomacs nil
  "Org 原生、模块化、可回滚的 Emacs 配置框架。"
  :group 'environment
  :prefix "loomacs-")

(defconst loomacs-version "0.1.0"
  "当前 Loomacs 框架版本。")

(defconst loomacs-manifest-format-version 1
  "当前支持的 Manifest 格式版本。")

(defcustom loomacs-minimum-emacs-version "30.2"
  "Loomacs 支持的最低 Emacs 版本。"
  :type 'string
  :group 'loomacs)

(defun loomacs-version ()
  "在 minibuffer 显示 Loomacs 版本，并返回版本字符串。"
  (interactive)
  (message "Loomacs %s" loomacs-version)
  loomacs-version)

(provide 'loomacs)
;;; loomacs.el ends here
