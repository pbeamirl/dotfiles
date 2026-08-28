;;; init.el -*- lexical-binding: t; -*-

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(setq use-package-always-ensure t)

;; Keep Custom's writes (package-selected-packages etc.) out of this
;; chezmoi-managed file.
(setq custom-file (locate-user-emacs-file "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file))

(set-face-attribute 'default nil
                    :family "BlexMono Nerd Font Mono" :height 150)

(use-package gruvbox-theme
  :config (load-theme 'gruvbox-dark-medium t))
