;;; init.el --- 加载 Org 生成的主配置 -*- lexical-binding: t; -*-

;; Emacs 只会自动读取 init.el；真正的人工维护入口是 config.org。这里仅加载
;; 已跟踪的生成文件，避免每次启动都提前加载 Org 或在启动路径写文件。
(defconst ssw/bootstrap-generated-config
  (expand-file-name "config.el" user-emacs-directory)
  "由 config.org 生成并供启动加载的配置文件。")

(unless (file-readable-p ssw/bootstrap-generated-config)
  (error "缺少生成配置 %s；请从 config.org 重新 tangle"
         ssw/bootstrap-generated-config))

(load ssw/bootstrap-generated-config nil 'nomessage)

(provide 'init)
;;; init.el ends here
