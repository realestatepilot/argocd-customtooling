FILE=/etc/vault.d/roleid
if [ -f "$FILE" ]; then
    export VAULT_TOKEN=$(cat /home/argocd/.vault_token)
fi
