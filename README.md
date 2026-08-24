# dotfiles

Dotfiles managed by [chezmoi](https://www.chezmoi.io/), for both Mac and Linux. Packages on macOS come from the `Brewfile`; on the NixOS machines, all installation lives in the sibling [nix-config](../nix-config) repo.

## Bootstrap (new machine)

```sh
chezmoi init --source ~/Repositories/github.com/unclebeam/dotfiles --apply
```

## Daily use

```sh
chezmoi diff    # what would change
chezmoi apply   # apply configs + run pending install scripts
```
