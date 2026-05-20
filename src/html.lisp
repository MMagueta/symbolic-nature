(defpackage :symbolic-nature.html
  (:use :cl)
  (:export #:html
           #:raw
           #:render-to-string))

(in-package :symbolic-nature.html)

;;; HTML generation DSL
;;; Usage: (html (:div :class "foo" (:p "Hello " (:strong "world"))))
;;; Produces: <div class="foo"><p>Hello <strong>world</strong></p></div>

(defstruct raw-html
  "Wraps a string that should not be escaped."
  content)

(defun raw (string)
  "Mark a string as raw HTML (no escaping)."
  (make-raw-html :content string))

(defun escape-html (string)
  "Escape HTML special characters in STRING."
  (let ((s (if (stringp string) string (princ-to-string string))))
    (with-output-to-string (out)
      (loop for ch across s do
        (case ch
          (#\& (write-string "&amp;" out))
          (#\< (write-string "&lt;" out))
          (#\> (write-string "&gt;" out))
          (#\" (write-string "&quot;" out))
          (t (write-char ch out)))))))

(defun void-element-p (tag)
  "Return T if TAG is a void/self-closing HTML element."
  (member tag '(:br :hr :img :input :meta :link :area :base :col :embed
                :source :track :wbr)
          :test #'eq))

(defun render-node (node stream)
  "Render a single HTML node to STREAM."
  (cond
    ;; nil -> nothing
    ((null node) nil)
    ;; raw html struct
    ((raw-html-p node)
     (write-string (raw-html-content node) stream))
    ;; string -> escaped text
    ((stringp node)
     (write-string (escape-html node) stream))
    ;; number -> text
    ((numberp node)
     (write-string (princ-to-string node) stream))
    ;; list starting with keyword -> element
    ((and (consp node) (keywordp (car node)))
     (render-element node stream))
    ;; list of nodes
    ((consp node)
     (dolist (child node)
       (render-node child stream)))
    (t (error "Unknown HTML node type: ~S" node))))

(defun render-element (form stream)
  "Render an element form (:tag :attr val ... children...) to STREAM."
  (let ((tag (string-downcase (symbol-name (car form))))
        (rest (cdr form))
        (attrs '())
        (children '()))
    ;; Parse attributes (keyword/value pairs) from children
    (loop while (and rest (keywordp (car rest))
                     (not (null (cdr rest))))
          do (push (cons (car rest) (cadr rest)) attrs)
             (setf rest (cddr rest)))
    ;; Remaining items are children
    (setf children rest)
    ;; Write opening tag
    (format stream "<~a" tag)
    (dolist (attr (nreverse attrs))
      (let ((name (string-downcase (symbol-name (car attr))))
            (value (cdr attr)))
        (cond
          ((eq value t) (format stream " ~a" name))
          ((eq value nil) nil)
          (t (format stream " ~a=\"~a\"" name (escape-html value))))))
    (if (void-element-p (car form))
        (write-string ">" stream)
        (progn
          (write-string ">" stream)
          (dolist (child children)
            (render-node child stream))
          (format stream "</~a>" tag)))))

(defun render-to-string (tree)
  "Render an HTML tree to a string."
  (with-output-to-string (s)
    (render-node tree s)))

(defmacro html (&body body)
  "Macro that renders HTML S-expressions to a string.
   Each form in BODY is rendered and concatenated."
  `(with-output-to-string (*html-output*)
     ,@(loop for form in body
             collect `(render-node ,form *html-output*))))

(defvar *html-output* nil
  "Stream used by the html macro for output.")
