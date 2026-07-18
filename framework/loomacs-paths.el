;;; loomacs-paths.el --- Loomacs 路径与文件边界 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW
;; URL: https://github.com/auspicious-ssw/loomacs
;; Package-Requires: ((emacs "30.2"))

;;; Commentary:

;; 统一定义源码、生成物、状态与缓存边界。加载本文件不会创建目录。

;;; Code:

(require 'loomacs)
(require 'subr-x)

(defconst loomacs-framework-directory
  (file-name-as-directory
   (file-name-directory (or load-file-name buffer-file-name default-directory)))
  "当前 Loomacs 框架内核所在目录。")

(defcustom loomacs-root-directory
  (file-name-as-directory
   (file-name-directory (directory-file-name loomacs-framework-directory)))
  "Loomacs 配置仓库根目录。"
  :type 'directory
  :group 'loomacs)

(defcustom loomacs-state-root
  (file-name-as-directory
   (expand-file-name "loomacs"
                     (or (getenv "XDG_STATE_HOME") "~/.local/state")))
  "Loomacs 持久状态根目录。"
  :type 'directory
  :group 'loomacs)

(defcustom loomacs-cache-root
  (file-name-as-directory
   (expand-file-name "loomacs"
                     (or (getenv "XDG_CACHE_HOME") "~/.cache")))
  "Loomacs 可重建缓存根目录。"
  :type 'directory
  :group 'loomacs)

(defun loomacs-path (&rest segments)
  "返回仓库根目录下由 SEGMENTS 组成的绝对路径。"
  (let ((path loomacs-root-directory))
    (dolist (segment segments path)
      (setq path (expand-file-name segment path)))))

(defun loomacs-generated-directory ()
  "返回 Git 跟踪的生成物目录。"
  (file-name-as-directory (loomacs-path "generated")))

(defun loomacs-state-directory ()
  "返回编辑器持久状态目录。"
  (file-name-as-directory (expand-file-name "state" loomacs-state-root)))

(defun loomacs-editor-cache-directory ()
  "返回编辑器运行缓存目录。"
  (file-name-as-directory (expand-file-name "editor" loomacs-cache-root)))

(defun loomacs-build-cache-directory ()
  "返回构建缓存目录。"
  (file-name-as-directory (expand-file-name "build" loomacs-cache-root)))

(defun loomacs-release-directory ()
  "返回本机 Release 根目录。"
  (file-name-as-directory (expand-file-name "releases" loomacs-state-root)))

(defun loomacs-log-directory ()
  "返回 Loomacs 日志目录。"
  (file-name-as-directory (expand-file-name "logs" loomacs-state-root)))

(defun loomacs-ensure-private-directory (directory)
  "创建 DIRECTORY，并把权限收紧为仅当前用户可访问。"
  (make-directory directory t)
  (set-file-modes directory #o700)
  directory)

(defun loomacs-safe-relative-path-p (path &optional extension)
  "PATH 是安全相对路径时返回非 nil。

PATH 不得为空、为绝对路径、包含父目录段或 NUL。若 EXTENSION 非 nil，
PATH 的扩展名必须与其相同。"
  (and (stringp path)
       (not (string-empty-p path))
       (not (file-name-absolute-p path))
       (not (string-match-p "\0" path))
       (let ((parts (split-string path "/" nil)))
         (and (not (memq nil parts))
              (not (member "" parts))
              (not (member "." parts))
              (not (member ".." parts))))
       (or (null extension)
           (string-equal (file-name-extension path) extension))))

(defun loomacs-expand-safe-path (relative base)
  "在 BASE 下展开安全相对路径 RELATIVE。

调用方应先用 `loomacs-safe-relative-path-p' 指定所需扩展名进行契约校验。"
  (unless (loomacs-safe-relative-path-p relative)
    (error "不安全的相对路径：%S" relative))
  (expand-file-name relative (file-name-as-directory base)))

(defun loomacs-path-inside-directory-p (path directory)
  "PATH 解析符号链接后仍位于 DIRECTORY 内时返回非 nil。"
  (condition-case nil
      (file-in-directory-p (file-truename path)
                           (file-name-as-directory (file-truename directory)))
    (file-error nil)))

(provide 'loomacs-paths)
;;; loomacs-paths.el ends here
