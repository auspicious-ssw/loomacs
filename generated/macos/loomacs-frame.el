;;; loomacs-frame.el --- Loomacs macOS Frame -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(setq frame-resize-pixelwise t
      window-resize-pixelwise t)

(add-to-list 'initial-frame-alist '(fullscreen . maximized))
(add-to-list 'default-frame-alist '(fullscreen . maximized))

(provide 'loomacs-frame)
;;; loomacs-frame.el ends here
