;;; loomacs-auth-source.el --- AI 凭据边界 -*- lexical-binding: t; -*-

(require 'auth-source)

(defconst loomacs-auth-source-recommended-file
  (expand-file-name "~/.authinfo.gpg")
  "建议由用户自行维护的加密 auth-source 文件；Loomacs 不创建或读取它。")

;; auth-source 默认可能缓存数小时。缩短到 15 分钟可减少解密凭据长期驻留内存，
;; 同时避免每个连续请求都重新解锁；这里只设置缓存生命周期，不触发凭据查询。
(setq auth-source-cache-expiry 900)

(provide 'loomacs-auth-source)
;;; loomacs-auth-source.el ends here
