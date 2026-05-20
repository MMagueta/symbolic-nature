(defpackage :symbolic-nature.site
  (:use :cl :symbolic-nature.html)
  (:export #:build-site))

(in-package :symbolic-nature.site)

;;; --- Configuration ---

(defvar *base-path* "/"
  "Base path for the site. Set to '/repo-name/' for GitHub Pages project sites.")

(defun base-url (path)
  "Prepend *base-path* to a relative PATH."
  (concatenate 'string *base-path* (string-left-trim "/" path)))

;;; --- Article data model ---

(defstruct article
  slug
  title
  date
  summary
  body)  ; body is a list of HTML s-expressions

;;; --- Layout components ---

(defun page-shell (title body-content)
  "Wrap BODY-CONTENT in the full page layout."
  `(:html :lang "en"
     (:head
       (:meta :charset "utf-8")
       (:meta :name "viewport" :content "width=device-width, initial-scale=1")
       (:title ,title)
       (:link :rel "stylesheet" :href ,(base-url "assets/style.css")))
     (:body
       ,(top-banner)
       ,(search-bar)
       ,(nav-tabs)
       ,(ticker)
       ,body-content
       ,(site-footer))))

(defun top-banner ()
  `(:header :class "site-header"
     (:div :class "header-left"
       (:h1 :class "site-title" "SYMBOLIC" (:span :class "title-sep" "_") "NATURE")
       (:p :class "site-tagline" "a tech magazine for the discerning curmudgeon"))))

(defun current-date-string ()
  (multiple-value-bind (sec min hr day month year)
      (get-decoded-time)
    (declare (ignore sec min hr))
    (format nil "~a ~d"
            (nth (1- month) '("JANUARY" "FEBRUARY" "MARCH" "APRIL" "MAY" "JUNE"
                              "JULY" "AUGUST" "SEPTEMBER" "OCTOBER" "NOVEMBER" "DECEMBER"))
            day)))

(defun search-bar ()
  nil)

(defun nav-tabs ()
  `(:nav :class "nav-tabs"
     (:a :href ,(base-url "") :class "active" "Home")
     (:a :href "#" "Rants")
     (:a :href "#" "Languages")
     (:a :href "#" "Tools")
     (:a :href "#" "Culture")
     (:a :href "#" "About")))

(defun ticker ()
  nil)

(defun site-footer ()
  `(:footer :class "site-footer"
     (:p "Symbolic Nature &copy; 2025 | "
         (:a :href ,(base-url "") "Home")
         " | Built with Common Lisp")))

;;; --- Sidebar components ---

(defun sidebar-left (categories)
  `(:aside :class "sidebar-left"
     (:h3 "Topics")
     (:ul
       ,@(loop for cat in categories
               collect `(:li (:a :href "#"
                               ,(string-capitalize cat)))))))

(defun sidebar-right (articles)
  `(:aside :class "sidebar-right"
     (:h3 "Latest Rants")
     (:div :class "sidebar-box"
       (:h4 "Recent")
       (:ul
         ,@(loop for a in (subseq articles 0 (min 5 (length articles)))
                 collect `(:li (:a :href ,(base-url (format nil "~a.html" (article-slug a)))
                                 ,(article-title a))))))))

;;; --- Page generators ---

(defun index-page (articles)
  "Generate the homepage."
  (let* ((categories '("rants" "languages" "tools" "culture" "opinions"))
         (featured (first articles))
         (rest-articles (rest articles)))
    (page-shell "Symbolic Nature"
      `(:div :class "main-layout"
         ,(sidebar-left categories)
         (:main :class "content-main"
           (:h1 ,(if featured (article-title featured) "Welcome to Symbolic Nature"))
           ,(when featured
              `(:div :class "headline-block"
                 (:div :class "headline-text"
                   (:p ,(article-summary featured))
                    (:a :href ,(base-url (format nil "~a.html" (article-slug featured)))
                      "Read more..."))))
           (:h2 "Today on Symbolic Nature")
           (:ul :class "article-list"
             ,@(loop for a in rest-articles
                     collect `(:li (:a :href ,(base-url (format nil "~a.html" (article-slug a)))
                                     ,(article-title a))))))
         ,(sidebar-right articles)))))

(defun article-page (article)
  "Generate a single article page."
  (page-shell (article-title article)
    `(:div :class "main-layout"
       ,(sidebar-left '("rants" "languages" "tools" "culture" "opinions"))
       (:main :class "content-main article-page"
         (:h1 ,(article-title article))
         (:div :class "article-meta"
           ,(format nil "Published: ~a" (article-date article)))
         ,@(article-body article))
       (:aside :class "sidebar-right"
         (:h3 "About")
         (:div :class "sidebar-box"
           (:p "Symbolic Nature is a tech magazine where I rant about programming, tools, languages, and the culture around them."))))))

;;; --- File I/O ---

(defun write-page (path content)
  "Write HTML content to a file at PATH."
  (ensure-directories-exist path)
  (with-open-file (out path :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
    (write-string "<!DOCTYPE html>" out)
    (write-string (render-to-string content) out))
  (format t "  wrote: ~a~%" path))

;;; --- Build ---

(defun build-site (output-dir articles)
  "Build the entire site into OUTPUT-DIR."
  (format t "Building Symbolic Nature...~%")
  ;; Index
  (write-page (merge-pathnames "index.html" output-dir)
              (index-page articles))
  ;; Article pages
  (dolist (a articles)
    (write-page (merge-pathnames (format nil "~a.html" (article-slug a)) output-dir)
                (article-page a)))
  ;; Copy assets
  (format t "Done. ~d pages generated.~%" (1+ (length articles))))
