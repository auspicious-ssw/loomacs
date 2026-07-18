;;; loomacs-environment.el --- Loomacs macOS 环境 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(defconst loomacs-macos-executable-prefixes
  '("/opt/homebrew/bin" "/usr/local/bin")
  "GUI Emacs 中允许查找工具的显式前缀。")

(defun loomacs-macos-find-executable (name)
  "返回 NAME 的可执行绝对路径，不修改 PATH。"
  (or (executable-find name)
      (catch 'found
        (dolist (prefix loomacs-macos-executable-prefixes)
          (let ((candidate (expand-file-name name prefix)))
            (when (file-executable-p candidate)
              (throw 'found candidate)))))))

(provide 'loomacs-environment)
;;; loomacs-environment.el ends here
