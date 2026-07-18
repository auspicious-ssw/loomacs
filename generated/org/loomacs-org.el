;;; loomacs-org.el --- Loomacs Org 领域 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(defvar org-directory)
(declare-function loomacs-register-packages "loomacs-packages" (&rest packages))

(defgroup loomacs-org nil
  "Loomacs 的 Org 文档、计划与 literate 配置。"
  :group 'loomacs
  :prefix "loomacs-org-")

(defcustom loomacs-org-directory
  (file-name-as-directory (expand-file-name "Org" "~/Documents"))
  "Loomacs Org 记录和计划文件的默认目录。"
  :type 'directory
  :group 'loomacs-org)

;; 让 Org 自身与 Agenda/Capture 共享同一可定制入口，但不在启动时创建目录。
(setq org-directory loomacs-org-directory)

(defconst loomacs-org-modules
  '(loomacs-org-core
    loomacs-org-modern
    loomacs-org-appear
    loomacs-org-agenda
    loomacs-org-capture
    loomacs-org-src)
  "Org 领域的有序子模块 feature 清单。")

(defconst loomacs-org-packages
  '(org-modern org-appear)
  "Org 领域直接使用的第三方包。")

(apply #'loomacs-register-packages loomacs-org-packages)

(provide 'loomacs-org)
;;; loomacs-org.el ends here
