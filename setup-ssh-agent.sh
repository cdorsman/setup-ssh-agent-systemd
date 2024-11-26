#!/bin/bash

main() {
    # Make the needed directories
    mkdir -p ~/.config/systemd/user/
    mkdir -p ~/.config/environment.d/

    # create Systemd unit file for ssh-agent
    cat > ~/.config/systemd/user/ssh-agent.service <<_EOF
[Unit]
Description=SSH key agent

[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
ExecStart=/usr/bin/ssh-agent -D -a $SSH_AUTH_SOCK

[Install]
WantedBy=default.target
_EOF

    # Create socket config
    echo "SSH_AUTH_SOCK=\"${XDG_RUNTIME_DIR}/ssh-agent.socket\"" > ~/.config/environment.d/ssh_auth_socket.conf

    # Create the directory if user SSH config does not exist
    if [ ! -f "~/.ssh/config" ]; then
        mkdir  ~/.ssh/config
        chmod 600 ~/.ssh/config
    fi

    # Enable and start ssh-agent as systemd service
    systemctl --user enable --now ssh-agent

    # Add keys automaticcally to agent
    echo 'AddKeysToAgent  yes' >> ~/.ssh/config

    if [ ! -f ~/.local/bin ];  then
        mkdir -p ~/.local/bin
    fi

    cat >> ~/.bash_profile <<__EOF
if [ -z "${SSH_AUTH_SOCK}" ]; then
    eval $(ssh-agent -s)
fi

priv_keys=()
for pub_key in ~/.ssh/*.pub
do
    priv_key=$(echo $pub_key | sed 's/\.pub//g')
    priv_keys+="$priv_key "
    priv_key=""
done

for priv_key in ${priv_keys[@]};
do
    ssh-add -l > /dev/null 2>&1 || ssh-add ${priv_key}
    priv_key=""
done
__EOF
}

main
