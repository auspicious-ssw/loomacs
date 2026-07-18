;;; loomacs-batppuccin.el --- Loomacs Batppuccin 主题 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(defun loomacs-load-preferred-theme ()
  "加载唯一首选主题；不可用时保留 Emacs 默认外观。"
  (mapc #'disable-theme custom-enabled-themes)
  (if (not (package-installed-p 'batppuccin))
      (message (concat "Batppuccin 未安装；当前保留 Emacs 默认外观。"
                       "可显式运行 M-x package-install-selected-packages"))
    (condition-case error-data
        (progn
          (require 'batppuccin)
          (load-theme 'batppuccin-mocha t))
      (error
       ;; 主题失败时清理所有可能的半加载 face，不伪装成备用主题成功。
       (mapc #'disable-theme custom-enabled-themes)
       (message "Batppuccin 加载失败；当前保留 Emacs 默认外观：%s"
                (error-message-string error-data))))))

(loomacs-load-preferred-theme)

(provide 'loomacs-batppuccin)
;;; loomacs-batppuccin.el ends here
