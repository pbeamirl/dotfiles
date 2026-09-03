# dotfiles

Dotfiles managed by [chezmoi](https://www.chezmoi.io/), for both Mac and Linux. Packages on macOS come from the `Brewfile`. `~/.ssh/config` is age-encrypted in the repo; the identity lives in `key.txt.age`, protected by a passphrase (backed up in 1Password).

## Bootstrap (fresh Mac)

0. In the macOS setup assistant, sign into iCloud / the App Store (needed for the `mas` apps).

1. Install Homebrew (also installs Xcode CLT, which provides git):

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   eval "$(/opt/homebrew/bin/brew shellenv)"   # for this first session only
   ```

2. Install chezmoi and clone this repo (HTTPS — no SSH keys exist yet):

   ```sh
   brew install chezmoi
   mkdir -p ~/Repositories/github.com/pbeamirl
   git clone https://github.com/pbeamirl/dotfiles.git ~/Repositories/github.com/pbeamirl/dotfiles
   ```

3. Run everything:

   ```sh
   chezmoi init --source ~/Repositories/github.com/pbeamirl/dotfiles --apply
   ```

   You'll be prompted for the **age passphrase** (restores the encryption key, then decrypts `.ssh/config`) and your **login password** (`chsh` to zsh). `brew bundle` installs all formulae, casks, and App Store apps; trackpad/keyboard defaults are applied.

4. Sign into 1Password → its SSH agent restores the work keys. Copy your personal GitHub key from 1Password into `~/.ssh/` (filename matching the `IdentityFile` in your ssh config) and `chmod 600` it.

5. Switch this repo's remote to SSH:

   ```sh
   git -C ~/Repositories/github.com/pbeamirl/dotfiles remote set-url origin git@github.com:pbeamirl/dotfiles.git
   ```

6. Open a new terminal; restore mise tools and verify:

   ```sh
   mise install          # installs the tools pinned in ~/.config/mise/config.toml
   chezmoi diff          # should be empty
   brew bundle check     # should be satisfied
   ```

## Daily use

```sh
chezmoi diff    # what would change
chezmoi apply   # apply configs + run pending install scripts
```

Editing `~/.ssh/config`: edit the live file, then `chezmoi re-add ~/.ssh/config` (re-encrypts; no passphrase needed).
