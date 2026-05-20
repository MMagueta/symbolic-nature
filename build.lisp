;;; build.lisp - Entry point for building the site
;;; Run with: sbcl --load build.lisp
;;; Set BASE_PATH env var for GitHub Pages project sites (e.g. /symbolic-nature/)

(load "src/html.lisp")
(load "src/site.lisp")

(in-package :symbolic-nature.site)

;; Configure base path from environment
(let ((env-base (sb-ext:posix-getenv "BASE_PATH")))
  (when (and env-base (plusp (length env-base)))
    (setf *base-path* env-base)))

;;; --- Sample articles ---

(defparameter *articles*
  (list
    (make-article
     :slug "lorem-ipsum"
     :title "Lorem Ipsum Dolor Sit Amet"
     :date "2025-05-18"
     :summary "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
     :body '((:p "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.")
             (:p "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
             (:p "Curabitur pretium tincidunt lacus. Nulla gravida orci a odio. Nullam varius, turpis et commodo pharetra, est eros bibendum elit, nec luctus magna felis sollicitudin mauris. Integer in mauris eu nibh euismod gravida.")
             (:p "Duis ac tellus et risus vulputate vehicula. Donec lobortis risus a elit. Etiam tempor. Ut ullamcorper, ligula ut dictum pharetra, nisi nunc fringilla magna, in commodo elit erat sit amet risus.")))))

;;; --- Build ---

(defparameter *output-dir*
  (merge-pathnames "output/" (truename ".")))

(build-site *output-dir* *articles*)

;; Copy CSS
(let ((src (merge-pathnames "assets/style.css" (truename ".")))
      (dst (merge-pathnames "assets/style.css" *output-dir*)))
  (ensure-directories-exist dst)
  (with-open-file (in src :direction :input)
    (with-open-file (out dst :direction :output :if-exists :supersede)
      (loop for line = (read-line in nil nil)
            while line do (write-line line out))))
  (format t "  copied: style.css~%"))

;; Write CNAME for GitHub Pages custom domain
(with-open-file (out (merge-pathnames "CNAME" *output-dir*)
                     :direction :output :if-exists :supersede)
  (write-string "symbolicnature.net" out))
(format t "  wrote: CNAME~%")

(format t "~%Site built successfully!~%")
(sb-ext:exit)
