#!/usr/bin/env fish

set DOTFILES_DIR (realpath (dirname (status -f)))
set CONFIG_DIR (test -n "$XDG_CONFIG_HOME"; and echo $XDG_CONFIG_HOME; or echo ~/.config)

echo "Installing dotfiles from $DOTFILES_DIR"

set configs fastfetch fish helix hypr kitty mako mpd nvim quickshell xdg-desktop-portal

for config in $configs
    set source "$DOTFILES_DIR/$config"
    set target "$CONFIG_DIR/$config"

    if test -e $source
        if test -L $target
            set current_target (readlink -f $target 2>/dev/null; or readlink $target)
            if test "$current_target" = "$source"
                echo "[OK] $config already linked correctly"
            else
                echo "[WARN] $config currently points to: $current_target"
                read -l -P "Retarget to $source? [y/N] " confirm
                switch $confirm
                    case y Y
                        rm $target
                        ln -s $source $target
                    case "*"
                        echo "[SKIP] Keeping existing symlink"
                end
            end
        else if test -e $target
            echo "[WARN] $config exists but is not a symlink, skipping"
        else
            ln -s $source $target
            echo "[LINK] Linked $config"
        end
    else
        echo "[ERROR] $config not found in dotfiles"
    end
end
