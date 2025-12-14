if status is-interactive
    function dcup --wraps='docker compose up' -d 'Docker compose up'
        docker compose up $argv
    end

    function dcdown --wraps 'docker compose down' -d 'Docker compose down'
        docker compose down $argv
    end

    function dclogs --wraps='docker compose logs' -d 'Docker compose logs'
        docker compose logs $argv
    end

    function zen --wraps='zen-browser' -d 'Zen Browser'
        zen-browser $argv
    end

    function please -d 'Execute previous command as sudo'
        eval sudo $history[1]
    end
end

eval (opam env)

source ~/.config/fish/secrets.fish 2>/dev/null
source ~/.config/fish/local.fish 2>/dev/null

set -x PATH "/home/intgrah/.ghcup/bin" $PATH
set -x PATH "/home/intgrah/.bun/bin" $PATH
set -x QML2_IMPORT_PATH /home/intgrah/dotfiles/quickshell $QML2_IMPORT_PATH
set -x PATH $HOME/.cargo/bin $PATH
