;;; loomacs-bookmark.el --- Loomacs 书签 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(eval-when-compile (require 'use-package))

(use-package bookmark
  :ensure nil
  :commands (bookmark-set bookmark-jump bookmark-bmenu-list))

(provide 'loomacs-bookmark)
;;; loomacs-bookmark.el ends here
