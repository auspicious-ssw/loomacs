;;; loomacs-gptel.el --- gptel buffer 工作流 -*- lexical-binding: t; -*-

(use-package gptel
  :if (package-installed-p 'gptel)
  :ensure nil
  :commands (gptel gptel-send gptel-menu gptel-rewrite gptel-add gptel-add-file)
  :init
  ;; 不设置 gptel-model/gptel-backend：可用模型会变化，应由已安装 gptel 与用户
  ;; 在发送前的菜单共同决定。默认 key resolver 继续使用 auth-source。
  (setq gptel-default-mode 'org-mode
        gptel-stream t
        gptel-use-curl (and (executable-find "curl") t)
        gptel-track-media nil
        gptel-use-tools nil
        gptel-confirm-tool-calls t))

(provide 'loomacs-gptel)
;;; loomacs-gptel.el ends here
