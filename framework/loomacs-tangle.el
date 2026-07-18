;;; loomacs-tangle.el --- Loomacs 显式 Org Tangle -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW
;; URL: https://github.com/auspicious-ssw/loomacs
;; Package-Requires: ((emacs "30.2"))

;;; Commentary:

;; 仅供显式构建调用。正常 Emacs 启动绝不加载 Org、扫描源文件或执行 Tangle。

;;; Code:

(require 'loomacs-log)

(defvar org-babel-src-block-regexp)
(defvar org-confirm-babel-evaluate)
(defvar org-mode-hook)

(declare-function org-babel-get-src-block-info "ob-core" (&optional light datum))
(declare-function org-babel-tangle-file "ob-tangle"
                  (file &optional target-file lang-re))

(define-error 'loomacs-tangle-error "Loomacs Tangle 失败")

(defun loomacs-file-sha256 (file)
  "返回 FILE 内容的 SHA-256 十六进制摘要。"
  (with-temp-buffer
    (insert-file-contents-literally file)
    (secure-hash 'sha256 (current-buffer))))

(defun loomacs-tangle--assert-target-neutral (source)
  "拒绝 SOURCE 中覆盖构建目标的 Emacs Lisp Tangle 参数。

Loomacs 必须把所有输出写入 staging。`:tangle yes' 或具体路径会让 Org 忽略
`org-babel-tangle-file' 的 TARGET 参数，可能改写源码旁文件，因此在任何写入前
拒绝；缺省值和显式 `:tangle no' 由构建器的 TARGET 参数安全覆盖。"
  (require 'org)
  (require 'ob-tangle)
  (with-temp-buffer
    (insert-file-contents source)
    (let ((org-mode-hook nil))
      (org-mode))
    (goto-char (point-min))
    (while (re-search-forward org-babel-src-block-regexp nil t)
      (let ((block-start (match-beginning 0))
            (next-position (match-end 0)))
        (goto-char block-start)
        (let* ((info (org-babel-get-src-block-info 'light))
               (language (car info))
               (parameters (nth 2 info))
               (tangle (cdr (assq :tangle parameters))))
          (when (and (string-equal language "emacs-lisp")
                     tangle
                     (not (string-equal (format "%s" tangle) "no")))
            (signal 'loomacs-tangle-error
                    (list
                     (format
                      (concat "%s:%d 使用了 :tangle %s；Loomacs 只允许缺省值或"
                              " :tangle no，由构建器统一写入 staging")
                      source (line-number-at-pos block-start) tangle)))))
        (goto-char next-position)))))

(defun loomacs-tangle-file (source target)
  "把 SOURCE 中的 Emacs Lisp 代码块显式 Tangle 到 TARGET。

此函数不刷新包索引、不安装包，并关闭用户 Org hook，确保维护命令不会因外观
插件或保存 hook 改写源码。"
  (unless (file-readable-p source)
    (signal 'loomacs-tangle-error
            (list (format "Org 源文件不可读：%s" source))))
  (loomacs-tangle--assert-target-neutral source)
  (make-directory (file-name-directory target) t)
  (when (file-exists-p target)
    (delete-file target))
  (condition-case error-data
      (let ((org-mode-hook nil)
            (after-save-hook nil)
            (org-confirm-babel-evaluate nil)
            (make-backup-files nil)
            (create-lockfiles nil)
            tangled-files)
        ;; Org/ob-tangle 是 Emacs 自带构建依赖；延迟 require 使运行时加载器不接触
        ;; Org，并让缺失构建能力在显式 build 阶段给出确定错误。
        (require 'org)
        (require 'ob-tangle)
        (setq tangled-files
              (org-babel-tangle-file source target "emacs-lisp"))
        (unless tangled-files
          (error "Org 没有返回任何 Tangle 输出"))
        (let ((expected (file-truename target)))
          (dolist (file tangled-files)
            (let ((actual (file-truename
                           (expand-file-name file (file-name-directory source)))))
              (unless (string-equal actual expected)
                (error "Tangle 越过 staging：期望 %s，实际 %s"
                       expected actual))))))
    (error
     (signal 'loomacs-tangle-error
             (list (format "Tangle 失败 %s -> %s：%s"
                           source target (error-message-string error-data))))))
  (unless (and (file-readable-p target)
               (> (file-attribute-size (file-attributes target)) 0))
    (signal 'loomacs-tangle-error
            (list (format "Tangle 没有产生有效文件：%s" target))))
  (loomacs-log 'debug "Tangle %s -> %s" source target)
  target)

(provide 'loomacs-tangle)
;;; loomacs-tangle.el ends here
