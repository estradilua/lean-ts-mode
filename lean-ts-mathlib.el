;;; lean-ts-mathlib.el --- Helpful commands for dealing with the Mathlib project  -*- lexical-binding: t; -*-

;; Copyright (C) 2025  Lua Viana Reis

;; Author: Lua Viana Reis <me@lua.blog.br>
;; Keywords: languages

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; 

;;; Code:

(require 'eglot)
(require 'magit)
(require 'lean-ts-lake)

(defun lean-ts-mathlib-checkout ()
  "Checkout the mathlib BRANCH in the project root."
  (interactive)
  (let ((server (eglot-current-server)))
    (eglot-shutdown server)
    (call-interactively #'magit-checkout)))


(provide 'lean-ts-mathlib)
;;; lean-ts-mathlib.el ends here
