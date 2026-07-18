;;; loomacs-startup.el --- Loomacs 启动默认值 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(setq inhibit-startup-screen t
      initial-scratch-message ""
      ring-bell-function #'ignore
      use-short-answers t
      sentence-end-double-space nil
      scroll-conservatively 101
      scroll-margin 3)

(setq-default indent-tabs-mode nil
              tab-width 4
              fill-column 100)

(provide 'loomacs-startup)
;;; loomacs-startup.el ends here
