# argocd-customtooling

Repo contains custom Docker to replace Docker from https://hub.docker.com/r/argoproj/argocd.

New Docker Repository location is https://hub.docker.com/r/realestatepilot/argocd-customtooling.

argocd secrets management is supported with additional tools:
* helm secrets
* sops
* vault

Vault Agent uses [AppRole Authentication](https://developer.hashicorp.com/vault/docs/auth/approle) and [Auto-Auth](https://developer.hashicorp.com/vault/docs/agent/autoauth/methods/approle). Vault Token is handled by Vault Agent so that the token is renewed regularly according to the TTL set.

## Usage

Docker parameter:
| Environment Variable | Description |
|-|-|
| VAULT_ADDR | Address of Vault Server, i.e. https://vault.organization.org:8200 |

Docker mounts:
|File|Content|
|-|-|
|/etc/vault.d/roleid|Approle RoleID|
|/etc/vault.d/secretid|AppRole SecretID|

### Configure Hashicorp Vault

A Hashicorp Vault is running and unsealed. So enable Transit Secret Engine.
```
kubectl exec -n vault -ti vault-0 -- vault secrets enable -path=transit transit
kubectl exec -n vault -ti vault-0 -- sh -c "vault write -f transit/keys/argocd"
```

After that configure auth between ArgoCD and Vault:
```
vault auth enable approle

vault policy write argocd -<<EOF
path "transit/decrypt/argocd" {
    capabilities = ["update"]
}
EOF

vault write auth/approle/role/argocd token_policies="argocd" \
    token_ttl=30m

# get soleID
vault read auth/approle/role/argocd/role-id
# get secretID
vault write -force auth/approle/role/argocd/secret-id

```


### Use in ArgoCD Deployment

Assuming ArgoCD is installed via helm. First create a Secret

```
kubectl create secret generic vault-approle-credentials -n argocd \
  --from-literal=roleid={replace with roleid} \
  --from-literal=secretid='{replace with secretid}'
```

Modify values.yaml:
```
server:
  config:
    helm.valuesFileSchemes: >-
      secrets+gpg-import, secrets+gpg-import-kubernetes,
      secrets+age-import, secrets+age-import-kubernetes,
      secrets,secrets+literal,
      https

...     

repoServer:
  image:
    repository: docker.io/realestatepilot/argocd-customtooling
    tag: v2.5.0-rc3-dev2
  env: 
  - name: VAULT_ADDR
    value: https://vault.wolke8.it
  volumeMounts:
  - name: appauth-role
    mountPath: /etc/vault.d/roleid
    readOnly: true
    subPath: roleid
  - name: appauth-secret
    mountPath: /etc/vault.d/secretid
    readOnly: true
    subPath: secretid
  volumes:
  - name: appauth-role
    secret:
      secretName: vault-approle-credentials
      items:
      - key: roleid
        path: roleid
  - name: appauth-secret
    secret:
      secretName: vault-approle-credentials
      items:
      - key: secretid
        path: secretid

``` 


## Thank you community!

This docker is based on the fantastic work by [ArgoProj](https://argoproj.github.io/) and the really useful [helm secrets plugin](https://github.com/jkroepke/helm-secrets).