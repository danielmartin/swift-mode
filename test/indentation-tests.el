;;; indentation-tests.el --- Test swift-mode indentation behaviour

;; Copyright (C) 2014 Chris Barrett

;; Author: Chris Barrett <chris.d.barrett@me.com>
;; Version: 0.1

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Test swift-mode indentation behaviour

;;; Code:

(require 'ert)
(require 'swift-mode)
(require 's)

;;; Test utilities

(defmacro check-indentation (description before after &optional var-bindings)
  "Declare an ert test for indentation behaviour.
The test will check that the swift indentation command changes the buffer
from one state to another.  It will also test that point is moved to an
expected position.

DESCRIPTION is a symbol describing the test.

BEFORE is the buffer string before indenting, where a pipe (|) represents
point.

AFTER is the expected buffer string after indenting, where a pipe (|)
represents the expected position of point.

VAR-BINDINGS is an optional let-bindings list.  It can be used to set the
values of customisable variables."
  (declare (indent 1))
  (let ((fname (intern (format "indentation/%s" description))))
    `(ert-deftest ,fname ()
       (let* ((after ,after)
              (expected-cursor-pos (1+ (s-index-of "|" after)))
              (expected-state (delete ?| after))

              ;; Bind customisable vars to default values for tests.
              (swift-indent-offset 4)
              (swift-indent-switch-case-offset 0)
              ,@var-bindings)
         (with-temp-buffer
           (insert ,before)
           (goto-char (point-min))
           (search-forward "|")
           (delete-char -1)
           (swift-mode)
           (indent-according-to-mode)

           (should (equal expected-state (buffer-string)))
           (should (equal expected-cursor-pos (point))))))))

;; Provide font locking for easier test editing.

(font-lock-add-keywords
 'emacs-lisp-mode
 `((,(rx "(" (group "check-indentation") eow)
    (1 font-lock-keyword-face))
   (,(rx "("
         (group "check-indentation") (+ space)
         (group bow (+ (not space)) eow)
         )
    (1 font-lock-keyword-face)
    (2 font-lock-function-name-face))))


;;; Tests


(check-indentation no-indentation-at-top-level
  "|x"
  "|x")

(check-indentation toplevel-exprs-indented-to-same-level/1
  "
x
|y
" "
x
|y
")

(check-indentation toplevel-exprs-indented-to-same-level/2
  "
x
     |y
" "
x
|y
")

(check-indentation nested-exprs-indented-to-same-level/1
  "
{
    x
    |y
}
" "
{
    x
    |y
}
")

(check-indentation nested-exprs-indented-to-same-level/2
  "
{
    x
        |y
}
" "
{
    x
    |y
}
")

(check-indentation nested-exprs-indented-to-same-level/3
  "
{
    x
|y
}
" "
{
    x
    |y
}
")

(check-indentation indent-if-body
  "
if true {
|x
}
" "
if true {
    |x
}
")

(check-indentation indent-if-body--no-effect-if-already-indented
  "
if true {
    |x
}
""
if true {
    |x
}
")

(check-indentation indents-case-statements-to-same-level-as-enclosing-switch/1
  "
switch true {
    |case
}
" "
switch true {
|case
}
")

(check-indentation indents-case-statements-to-same-level-as-enclosing-switch/2
  "
switch true {
          |case
}
" "
switch true {
|case
}
")

(check-indentation indents-case-statements-to-same-level-as-enclosing-switch/3
  "
{
    switch true {
|case
    }
}
" "
{
    switch true {
    |case
    }
}
")

(check-indentation indents-case-statements-to-same-level-as-enclosing-switch/4
  "
{
    switch true {
              |case
    }
}
" "
{
    switch true {
    |case
    }
}
")


(check-indentation indents-case-statement-bodies/1
"
switch x {
case y:
|return z
}
" "
switch x {
case y:
    |return z
}
")

(check-indentation indents-case-statement-bodies/2
"
switch x {
case y:
       |return z
}
" "
switch x {
case y:
    |return z
}
")

(check-indentation indents-case-statement-bodies/3
"
switch x {
case y:
    |return z
}
" "
switch x {
case y:
    |return z
}
")

(check-indentation indents-case-statement-bodies/4
"
switch x {
case y:
    x
    |return z
}
" "
switch x {
case y:
    x
    |return z
}
")

(check-indentation indents-case-statement-bodies/5
"
switch x {
case y:
    x
|return z
}
" "
switch x {
case y:
    x
    |return z
}
")

(check-indentation indents-case-statement-bodies/6
"
switch x {
case y:
    x
        |return z
}
" "
switch x {
case y:
    x
    |return z
}
")


(check-indentation indents-default-statements-to-same-level-as-enclosing-switch/1
  "
{
    switch true {
|default
    }
}
" "
{
    switch true {
    |default
    }
}
")

(check-indentation indents-default-statements-to-same-level-as-enclosing-switch/2
  "
{
    switch true {
              |default
    }
}
" "
{
    switch true {
    |default
    }
}
")

(check-indentation indents-case-statements-to-user-defined-offset/1
  "
switch true {
    |case
}
" "
switch true {
  |case
}
"
((swift-indent-switch-case-offset 2)))

(check-indentation indents-case-statements-to-user-defined-offset/2
  "
switch true {
          |case
}
" "
switch true {
  |case
}
"
((swift-indent-switch-case-offset 2)))


(check-indentation indents-case-statements-in-enum/1
  "
enum T {
|case
}
" "
enum T {
    |case
}
")

(check-indentation indents-case-statements-in-enum/2
  "
enum T {
         |case
}
" "
enum T {
    |case
}
")

(provide 'indentation-tests)

;;; indentation-tests.el ends here