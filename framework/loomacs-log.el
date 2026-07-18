;;; loomacs-log.el --- Loomacs 结构化日志 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW
;; URL: https://github.com/auspicious-ssw/loomacs
;; Package-Requires: ((emacs "30.2"))

;;; Commentary:

;; 为构建、诊断和启动提供统一日志入口。默认仅写 *Messages*；显式维护命令可
;; 临时开启文件日志。日志不得包含密钥或认证对象。

;;; Code:

(require 'loomacs-paths)

(defcustom loomacs-log-level 'info
  "最低日志级别，可取 debug、info、warning 或 error。"
  :type '(choice (const debug) (const info) (const warning) (const error))
  :group 'loomacs)

(defcustom loomacs-log-to-file nil
  "非 nil 时把日志同时追加到 XDG state 日志文件。"
  :type 'boolean
  :group 'loomacs)

(defconst loomacs-log--levels
  '((debug . 10) (info . 20) (warning . 30) (error . 40))
  "日志级别排序。")

(defun loomacs-log--enabled-p (level)
  "LEVEL 达到当前最低日志级别时返回非 nil。"
  (>= (or (alist-get level loomacs-log--levels) 20)
      (or (alist-get loomacs-log-level loomacs-log--levels) 20)))

(defun loomacs-log-file ()
  "返回当天 Loomacs 日志文件。"
  (expand-file-name (format-time-string "%Y-%m-%d.log")
                    (loomacs-log-directory)))

(defun loomacs-log (level format-string &rest arguments)
  "按 LEVEL 记录 FORMAT-STRING 与 ARGUMENTS 组成的消息。"
  (when (loomacs-log--enabled-p level)
    (let* ((text (apply #'format format-string arguments))
           (line (format "%s %-7s %s"
                         (format-time-string "%Y-%m-%dT%H:%M:%S%z")
                         (upcase (symbol-name level))
                         text)))
      (message "Loomacs: %s" text)
      (when loomacs-log-to-file
        ;; 可观测性不能反过来破坏已验证配置的发布或启动；文件系统只读、磁盘满
        ;; 等日志故障降级到 *Messages*，核心操作仍按自身事务结果返回。
        (condition-case error-data
            (let* ((directory (loomacs-ensure-private-directory
                               (loomacs-log-directory)))
                   (file (expand-file-name (file-name-nondirectory
                                            (loomacs-log-file))
                                           directory)))
              (write-region (concat line "\n") nil file 'append 'silent)
              (set-file-modes file #o600))
          (error
           (message "Loomacs: 文件日志写入失败：%s"
                    (error-message-string error-data))))))))

(defmacro loomacs-with-file-logging (&rest body)
  "执行 BODY，并在此动态范围内启用文件日志。"
  (declare (indent 0) (debug t))
  `(let ((loomacs-log-to-file t))
     ,@body))

(provide 'loomacs-log)
;;; loomacs-log.el ends here
