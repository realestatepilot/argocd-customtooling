echo "run .bashrc" >> /tmp/sops-wrapper.log

FILE=/etc/vault.d/roleid
if [ -f "$FILE" ]; then
    export VAULT_TOKEN=$(cat /tmp/.vault_token)
fi
