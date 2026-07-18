;;; init.el --- Loomacs 稳定离线入口 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

;; init.el 只定位并调用稳定 bootstrap。正常启动不加载 Org 构建器、不扫描模块、
;; 不安装包、不刷新软件源，也不访问网络。
(defconst loomacs-init-root-directory
  (file-name-as-directory
   (file-name-directory (or load-file-name user-init-file user-emacs-directory)))
  "当前 Loomacs 配置仓库根目录。")

(defconst loomacs-init-bootstrap-file
  (expand-file-name "framework/loomacs-bootstrap.el"
                    loomacs-init-root-directory)
  "Loomacs 稳定 bootstrap 文件。")

(unless (file-readable-p loomacs-init-bootstrap-file)
  (error "缺少 Loomacs bootstrap：%s" loomacs-init-bootstrap-file))

(declare-function loomacs-bootstrap "loomacs-bootstrap")

(load loomacs-init-bootstrap-file nil 'nomessage t)
(loomacs-bootstrap)

(provide 'init)
;;; init.el ends here
