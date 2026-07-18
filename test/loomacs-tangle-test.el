;;; loomacs-tangle-test.el --- Loomacs Tangle 边界测试 -*- lexical-binding: t; -*-

;; Author: SSW
;; Maintainer: SSW
;; URL: https://github.com/auspicious-ssw/loomacs
;; Package-Requires: ((emacs "30.2"))

;;; Code:

(require 'ert)
(require 'loomacs-tangle)

(ert-deftest loomacs-tangle-writes-only-explicit-target ()
  (let* ((directory (make-temp-file "loomacs-tangle-test-" t))
         (source (expand-file-name "module.org" directory))
         (staging (expand-file-name "staging/module.el" directory)))
    (unwind-protect
        (progn
          (with-temp-file source
            (insert "#+begin_src emacs-lisp\n"
                    "(provide 'loomacs-test-tangle)\n"
                    "#+end_src\n"))
          (should (string-equal (loomacs-tangle-file source staging) staging))
          (should (file-readable-p staging))
          (should-not (file-exists-p (expand-file-name "module.el" directory))))
      (delete-directory directory t))))

(ert-deftest loomacs-tangle-rejects-explicit-yes-before-writing ()
  (let* ((directory (make-temp-file "loomacs-tangle-test-" t))
         (source (expand-file-name "module.org" directory))
         (staging (expand-file-name "staging/module.el" directory)))
    (unwind-protect
        (progn
          (with-temp-file source
            (insert "#+property: header-args:emacs-lisp :tangle yes\n"
                    "#+begin_src emacs-lisp\n"
                    "(provide 'loomacs-test-tangle-escape)\n"
                    "#+end_src\n"))
          (should-error (loomacs-tangle-file source staging)
                        :type 'loomacs-tangle-error)
          (should-not (file-exists-p staging))
          (should-not (file-exists-p (expand-file-name "module.el" directory))))
      (delete-directory directory t))))

(provide 'loomacs-tangle-test)
;;; loomacs-tangle-test.el ends here
