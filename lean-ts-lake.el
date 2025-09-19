;;; lean-ts-lake.el --- Lake commands for `lean-ts-mode'  -*- lexical-binding: t; -*-

;; Copyright (c) 2025 Lua Viana Reis. All rights reserved.

;; Author: Lua <me@lua.blog.br>
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

(require 'project)
(require 'magit)

(defvar lean-ts-lake-command "lake"
  "The command to run Lake.")

(defun lean-ts-lake (args)
  "Run Lake with ARGS in the project root."
  (interactive "sRun command: lake ")
  (let* ((default-directory (project-root (project-current t)))
         (command (concat lean-ts-lake-command " " args)))
    (if default-directory
        (compilation-start command))))

(defun lean-ts-lake-build ()
  "Run `lake build` in the project root."
  (interactive)
  (lean-ts-lake "build"))

(defun lean-ts-lake-cache-get ()
  "Run `lake exe cache get` in the project root."
  (interactive)
  (lean-ts-lake "exe cache get"))

(provide 'lean-ts-lake)
;;; lean-ts-lake.el ends here
