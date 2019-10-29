;; Evil mode, definitions used by packages below
(use-package evil
  :demand t
  :commands (evil-define-key evil-define-motion evil-global-set-key)
  :init
  (setq-default evil-want-keybinding nil)
  (setq-default evil-want-C-u-scroll t)
  (setq-default evil-search-module 'evil-search)
  (setq-default evil-ex-search-persistent-highlight nil)
  :config
  (evil-mode 1)
  (global-undo-tree-mode -1)

  ;; Useful operators
  (evil-global-set-key 'normal (kbd "gca")
                       (evil-define-operator my/figlet (beg end)
                         (shell-command-on-region beg end "figlet" (current-buffer) t)

                         (whitespace-cleanup-region (region-beginning) (region-end))
                         (comment-region (region-beginning) (region-end))
                         (indent-region-line-by-line (region-beginning) (region-end))))
  (evil-global-set-key 'normal (kbd "gc=")
                       (evil-define-operator my/align-eq (beg end)
                         ;; Align equal
                         (align-regexp beg end "\\(\\s-*\\)=")))
  (evil-global-set-key 'normal (kbd "g c SPC")
                       (evil-define-operator my/align-word (beg end)
                         ;; Align all non-whitespace characters preceeded by at least 2 spaces
                         (align-regexp beg end "\\(\\s-+\\)\\s-[^\\s-]" nil nil t)))
  (evil-global-set-key 'normal (kbd "gs")
                       (evil-define-operator my/sort (beg end)
                         (sort-lines nil beg end)))
  (evil-global-set-key 'normal (kbd "gyf") (lambda ()
                                             (interactive)
                                             (kill-new (buffer-file-name))
                                             (message "%s" (buffer-file-name))))

  ;; Other useful shorthands
  (evil-global-set-key 'normal (kbd "gt") 'switch-to-buffer)
  (evil-global-set-key 'normal (kbd "gcc") 'comment-or-uncomment-region)
  (evil-global-set-key 'normal (kbd "gcw") 'delete-trailing-whitespace)
  (evil-global-set-key 'normal (kbd "D") (lambda ()
                                           (interactive)
                                           (beginning-of-line)
                                           (kill-line)))

  ;; Insert mode shortcuts
  (evil-global-set-key 'insert (kbd "C-c d")
                       (lambda (prefix)
                         (interactive "P")
                         (insert (format-time-string
                                  (if prefix
                                      (let* ((seconds (car (current-time-zone)))
                                             (minutes (/ seconds 60))
                                             (hours   (/ minutes 60)))
                                        (concat "%FT%T" (format "%+.2d:%.2d" hours (% minutes 60))))
                                    "%F")))))
  (evil-global-set-key 'insert (kbd "C-c n")
                       (lambda (num)
                         (interactive "nInput start number: ")
                         (kmacro-set-counter num)))

  (add-hook 'eshell-mode-hook
            (defun my/eshell-hook ()
              (evil-define-key 'insert eshell-mode-map (kbd "C-d")
                (lambda ()
                  (interactive)
                  (unless (eshell-send-eof-to-process)
                    (kill-buffer))))))

  ;; Disable search highlights after short duration
  (defvar my/stop-hl-timer-last nil)
  (defun my/stop-hl-timer (_)
    (when my/stop-hl-timer-last
      (cancel-timer my/stop-hl-timer-last))
    (setq my/stop-hl-timer-last
          (run-at-time 1 nil (lambda () (evil-ex-nohighlight)))))
  (advice-add 'evil-ex-search-activate-highlight :after 'my/stop-hl-timer)

  (evil-set-initial-state 'ses-mode 'emacs))

;; Other packages

(use-package base16-theme
  :config
  (load-theme 'base16-tomorrow-night t)
  (defun my/reload-dark ()
    (load-theme 'base16-tomorrow-night t)
    (defun my/get-color (base)
      (plist-get base16-tomorrow-night-colors base))
    (modify-face 'trailing-whitespace (my/get-color :base00) (my/get-color :base08))
    (modify-face 'line-number-current-line (my/get-color :base05) (my/get-color :base00) nil t)
    (modify-face 'line-number (my/get-color :base04) (my/get-color :base00)))
  (my/reload-dark)
  (defun blind-me ()
    (interactive)
    (if (custom-theme-enabled-p 'base16-tomorrow-night)
        (progn
          (disable-theme 'base16-tomorrow-night)
          (load-theme 'base16-tomorrow t))
      (progn
        (disable-theme 'base16-tomorrow)
        (my/reload-dark)))))
(use-package chess
  :pin gnu)
(use-package company
  :config
  (global-company-mode 1)
  (setq company-idle-delay 0)
  (evil-define-key 'insert 'company-mode-hook (kbd "C-n") 'company-select-next-if-tooltip-visible-or-complete-selection)
  (evil-define-key 'insert 'company-mode-hook (kbd "C-p") 'company-select-previous))
(use-package company-auctex)
(use-package company-lsp)
(use-package counsel
  :demand t
  :config
  (counsel-mode 1))
(use-package direnv
  :config
  (direnv-mode 1))
(use-package dockerfile-mode
  :mode "Dockerfile\\'")
(use-package edit-indirect) ;; For editing blocks inside markdown!
(use-package edit-server ;; https://www.emacswiki.org/emacs/Edit_with_Emacs
  :config
  (setq edit-server-new-frame nil)
  (edit-server-start))
(use-package evil-args
  :config
  (define-key evil-inner-text-objects-map "a" 'evil-inner-arg)
  (define-key evil-outer-text-objects-map "a" 'evil-outer-arg)
  (evil-define-key 'normal 'prog-mode-map (kbd "M-n")
    (lambda ()
      "Interchange the next two arguments, leaving the point at the end of the latter"
      (interactive)
      (destructuring-bind (start1 end1 _) (evil-inner-arg)
        ;; Get the text of the first argument
        (let ((text1 (buffer-substring-no-properties start1 end1)))
          (evil-forward-arg 1)

          ;; Get the text of the second argument
          (let ((text2 (destructuring-bind (start2 end2 _) (evil-inner-arg)
                         (buffer-substring-no-properties start2 end2))))

            ;; Replace the first
            (delete-region start1 end1)
            (save-excursion
              (goto-char start1)
              (insert text2)))

          ;; Re-obtain text (because marks probably changed) and replace second
          (destructuring-bind (start2 end2 _) (evil-inner-arg)
            (delete-region start2 end2)
            (goto-char start2)
            (save-excursion
              (insert text1))))))))
(use-package evil-collection
  :config
  (evil-collection-init))
(use-package evil-easymotion
  :config
  (evilem-default-keybindings "SPC"))
(use-package evil-magit
  :bind ("C-c g" . magit-status)
  :demand t)
(use-package evil-surround
  :config
  (global-evil-surround-mode 1))
(use-package flycheck
  :hook (lsp-ui-mode . flycheck-mode))
(use-package gist
  :commands (gist-region-private)
  :init
  (defun gist (start end)
    (interactive "r")
    (gist-region-private start end)))
(use-package go-mode
  :mode "\\.go\\'"
  :hook (go-mode . lsp)
  :init
  (defun goimports ()
    (interactive)
    (when (derived-mode-p 'go-mode)
      (let ((old-pos (point))
            (old-buffer (current-buffer)))
        (let ((new-content (with-temp-buffer
                             (insert-buffer old-buffer)
                             (when (eq (shell-command-on-region (buffer-end 0) (buffer-end 1)
                                                                "goimports" (current-buffer) t
                                                                "GoImports Errors" t)
                                       0)
                               (buffer-string)))))
          (when new-content
            (delete-region (buffer-end 0) (buffer-end 1))
            (insert new-content)
            (goto-char old-pos)))))))
(use-package htmlize) ;; For org mode
(use-package hydra)
(use-package ivy
  :config
  (ivy-mode 1))
(use-package imenu-list
  :bind ("C-c i" . imenu-list-smart-toggle))
(use-package json-mode
  :mode "\\.json\\'")
(use-package lsp-mode
  :bind ("C-c e" . lsp-extend-selection)
  :commands lsp
  :hook (python-mode . lsp)
  :config
  (setq lsp-prefer-flymake nil)
  (setq lsp-auto-guess-root t))
(use-package lsp-ui
  :after lsp-mode
  :hook (lsp-mode . lsp-ui-mode)
  :custom
  (lsp-ui-doc-max-width 50)
  (lsp-ui-doc-max-height 20))
(use-package markdown-mode
  :hook (markdown-mode . flycheck-mode)
  :mode "\\.md\\'"
  :custom
  (markdown-header-scaling t))
(use-package nasm-mode
  :hook (asm-mode . nasm-mode))
(use-package nix-mode
  :hook (nix-mode . lsp)
  :mode "\\.nix\\'"
  :config
  (add-to-list 'lsp-language-id-configuration '(nix-mode . "nix"))
  (lsp-register-client
   (make-lsp-client :new-connection (lsp-stdio-connection '("bash" "-c" "env RUST_LOG=trace rnix-lsp 2> /tmp/nix-lsp.log"))
                    :major-modes '(nix-mode)
                    :server-id 'nix))
  (setq nix-mode-use-smie t)
  (define-key nix-mode-map (kbd "C-M-x") (lambda (beg end)
                                             (interactive "r")
                                             (shell-command-on-region beg end "nix-instantiate --eval -")))
  (define-key nix-mode-map (kbd "C-c m") (lambda ()
                                           (interactive)
                                           (load "man")
                                           (let ((original-notify Man-notify-method))
                                             (setq Man-notify-method 'pushy)
                                             (man "configuration.nix")
                                             (setq Man-notify-method original-notify)))))
(use-package org
  :mode ("\\.org\\'". org-mode)
  :commands (org-mode)
  :custom ((org-startup-indented t)
           (org-startup-folded nil)))
(use-package powerline
  :config
  (powerline-center-evil-theme))
(use-package projectile
  :after projectile-ripgrep
  :demand t
  :custom ((projectile-completion-system 'ivy)
           (projectile-project-search-path '("~/" "~/Coding/Rust/" "~/Coding/Rust/external/")))
  :config
  (projectile-mode 1)
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map))
(use-package projectile-ripgrep)
(use-package ranger
  :bind ("C-c r" . ranger)
  :custom ((ranger-override-dired 'ranger)
           (ranger-override-dired-mode t)))
(use-package rustic
  :hook (rustic-mode . lsp)
  :mode ("\\.rs\\'" . rustic-mode)
  :config
  (sp-local-pair 'rustic-mode "<" ">"))
(use-package rust-playground
  :after rustic-mode
  :commands (rust-playground rust-playground-mode))
(use-package slime
  :after slime-company
  :mode "\\.lisp\\'"
  :commands slime
  :config
  (setq inferior-lisp-program "sbcl --noinform")
  (slime-setup '(slime-fancy slime-company)))
(use-package slime-company)
(use-package smartparens
  :demand t
  :commands sp-local-pairs
  :bind (("C-M-l" . sp-forward-slurp-sexp)
         ("C-M-h" . sp-forward-barf-sexp))
  :config
  (require 'smartparens-config)
  (smartparens-global-mode 1)
  (show-smartparens-global-mode 1)

  ;; Allow using smartparens from minibuffer
  (setq sp-ignore-modes-list (remove 'minibuffer-inactive-mode sp-ignore-modes-list))

  ;; Configure evil to use smartparens for %
  (evil-define-motion my/matching-paren (num)
    :type inclusive
    (let* ((expr (sp-get-paired-expression))
           (begin (plist-get expr :beg))
           (next (plist-get expr :end))
           (end (if next (- next 1) nil)))
      (if (eq (point) end)
          (goto-char begin)
        (when end (goto-char end)))))
  (evil-global-set-key 'motion (kbd "%") 'my/matching-paren)

  ;; Create double newline on enter
  (defun my/newline-indent (&rest _ignored)
    "Call when newline is pressed - this will only add one newline"
    (newline)
    (indent-according-to-mode)
    (forward-line -1)
    (indent-according-to-mode))
  (sp-local-pair 'prog-mode "{" nil :post-handlers '((my/newline-indent "RET")))
  (sp-local-pair 'prog-mode "(" nil :post-handlers '((my/newline-indent "RET")))
  (sp-local-pair 'prog-mode "[" nil :post-handlers '((my/newline-indent "RET"))))
(use-package string-inflection
  :after transient
  :config
  (defhydra my/string-inflection-keys (global-map "C-c")
    "
Toggle string casing
--------------------
[_s_]: snake%(quote _)case
[_S_]: SCREAMING%(quote _)SNAKE%(quote _)CASE
[_k_]: kebab-case
[_c_]: camelCase
[_C_]: PascalCase
"
    ("_" string-inflection-cycle "Cycle common")
    ("-" string-inflection-all-cycle "Cycle all" :bind nil)
    ("s" string-inflection-underscore :bind nil)
    ("S" string-inflection-upcase :bind nil)
    ("k" string-inflection-kebab-case :bind nil)
    ("c" string-inflection-lower-camelcase :bind nil)
    ("C" string-inflection-camelcase :bind nil)))
(use-package sublimity
  :config
  (require 'sublimity-scroll)
  (sublimity-mode 1))
(use-package auctex
  :mode ("\\.tex\\'" . LaTeX-mode)
  :pin gnu)
(use-package yaml-mode
  :mode "\\.yml\\'")
