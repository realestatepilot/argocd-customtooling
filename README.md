> Breaking change: we publish to ghcr.io instead of docker.io from >v2.6.5 (2023-03-15)

# argocd-customtooling

## Approach
Using ArgoCD with helm secrets and sops is well documented if you use gpg or age encryption. The downside of this is a difficult key management. If a member of a midsize team leave and decryption should no longer work for this member you have to renew all encrypted files with a new key. Very challenging and often not possible just in time.

This repo offers a solution. Sops can be used also with Vault Transit Encryption Engine. Team Members get a personal account (token) to this engine. Argo Repo Server can use to decrypt sops based files with an other token. Due the seperate authentification if a team member get´s lost, trust is no longer a problem.

## Content
Repo contains custom Docker to replace Docker from https://hub.docker.com/r/argoproj/argocd.

New Docker Repository location is https://ghcr.io/realestatepilot/argocd-customtooling.

argocd secrets management is supported with additional tools:
* helm secrets
* sops
* vault

Vault Agent uses [AppRole Authentication](https://developer.hashicorp.com/vault/docs/auth/approle) and [Auto-Auth](https://developer.hashicorp.com/vault/docs/agent/autoauth/methods/approle). Vault Token is handled by Vault Agent so that the token is renewed regularly according to the TTL set.

If ArgoProj releases new Versions, Github Action triggers a new build for this Docker also.

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

## Changes

2023-03-16

* move docker image from docker.io to ghcr.io

2022-11-03 

* restart vault agent if not running #1
