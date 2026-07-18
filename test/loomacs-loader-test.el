;;; loomacs-loader-test.el --- Loomacs 精确加载测试 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW
;; URL: https://github.com/auspicious-ssw/loomacs
;; Package-Requires: ((emacs "30.2"))

;;; Code:

(require 'ert)
(require 'loomacs-loader)

(defvar loomacs-test-loader-order nil)

(defun loomacs-test-loader--write-manifest (directory manifest)
  "把 MANIFEST 写入 DIRECTORY。"
  (with-temp-file (expand-file-name "loomacs-manifest.el" directory)
    (insert "(setq loomacs-manifest '")
    (prin1 manifest (current-buffer))
    (insert ")\n(provide 'loomacs-manifest)\n")))

(ert-deftest loomacs-loader-loads-exact-files-in-dependency-order ()
  (let ((directory (make-temp-file "loomacs-loader-test-" t))
        (loomacs-test-loader-order nil))
    (unwind-protect
        (let ((manifest
               '(:format 1 :profile test
                 :modules
                 ((:id loader-b :feature loomacs-test-loader-b
                   :source "b.org" :output "b.el" :requires (loader-a))
                  (:id loader-a :feature loomacs-test-loader-a
                   :source "a.org" :output "a.el" :requires nil)))))
          (with-temp-file (expand-file-name "a.el" directory)
            (insert "(setq loomacs-test-loader-order (append loomacs-test-loader-order '(a)))\n"
                    "(provide 'loomacs-test-loader-a)\n"))
          (with-temp-file (expand-file-name "b.el" directory)
            (insert "(setq loomacs-test-loader-order (append loomacs-test-loader-order '(b)))\n"
                    "(provide 'loomacs-test-loader-b)\n"))
          (loomacs-test-loader--write-manifest directory manifest)
          (should (equal (loomacs-loader-load-manifest
                          (expand-file-name "loomacs-manifest.el" directory))
                         '(loader-a loader-b)))
          (should (equal loomacs-test-loader-order '(a b)))
          (should (equal loomacs-active-profile 'test)))
      (delete-directory directory t)
      (setq features (delq 'loomacs-test-loader-a features)
            features (delq 'loomacs-test-loader-b features)))))

(ert-deftest loomacs-loader-preflight-rejects-missing-file-before-loading ()
  (let ((directory (make-temp-file "loomacs-loader-test-" t))
        (loomacs-test-loader-order nil))
    (unwind-protect
        (let ((manifest
               '(:format 1
                 :modules
                 ((:id loader-present :feature loomacs-test-loader-present
                   :source "present.org" :output "present.el" :requires nil)
                  (:id loader-missing :feature loomacs-test-loader-missing
                   :source "missing.org" :output "missing.el"
                   :requires (loader-present))))))
          (with-temp-file (expand-file-name "present.el" directory)
            (insert "(setq loomacs-test-loader-order '(loaded))\n"
                    "(provide 'loomacs-test-loader-present)\n"))
          (loomacs-test-loader--write-manifest directory manifest)
          (should-error
           (loomacs-loader-load-manifest
            (expand-file-name "loomacs-manifest.el" directory))
           :type 'loomacs-module-error)
          (should-not loomacs-test-loader-order))
      (delete-directory directory t)
      (setq features (delq 'loomacs-test-loader-present features)))))

(provide 'loomacs-loader-test)
;;; loomacs-loader-test.el ends here
