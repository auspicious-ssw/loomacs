;;; loomacs-doom-modeline.el --- Loomacs Doom Modeline -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW <https://github.com/auspicious-ssw>

(eval-when-compile (require 'use-package))

(use-package doom-modeline
  :if (package-installed-p 'doom-modeline)
  :ensure nil
  :demand t
  :init
  (setq doom-modeline-height 32
        doom-modeline-bar-width 4
        doom-modeline-hud nil
        doom-modeline-window-width-limit 80
        doom-modeline-buffer-file-name-style 'relative-to-project
        doom-modeline-icon t
        doom-modeline-major-mode-icon t
        doom-modeline-major-mode-color-icon t
        doom-modeline-buffer-state-icon t
        doom-modeline-buffer-modification-icon t
        doom-modeline-buffer-name t
        doom-modeline-highlight-modified-buffer-name t
        doom-modeline-column-zero-based nil
        doom-modeline-percent-position '(-3 "%p")
        doom-modeline-position-column-line-format '("%l:%c")
        doom-modeline-enable-buffer-position t
        doom-modeline-selection-info t
        doom-modeline-project-name t
        doom-modeline-vcs-icon t
        doom-modeline-vcs-max-length 24
        doom-modeline-check-icon t
        doom-modeline-check 'auto
        doom-modeline-lsp t
        doom-modeline-lsp-icon t
        doom-modeline-remote-host t
        doom-modeline-env-version t
        doom-modeline-minor-modes nil
        doom-modeline-enable-word-count nil
        doom-modeline-buffer-encoding nil
        doom-modeline-indent-info nil
        doom-modeline-total-line-number nil
        doom-modeline-workspace-name nil
        doom-modeline-persp-name nil
        doom-modeline-modal nil
        doom-modeline-github nil
        doom-modeline-battery nil
        doom-modeline-time nil
        doom-modeline-display-misc-in-all-mode-lines nil)
  :config
  (doom-modeline-mode 1))

(provide 'loomacs-doom-modeline)
;;; loomacs-doom-modeline.el ends here
