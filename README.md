# argocd-customtooling

Repo contains custom Docker to replace Docker from https://hub.docker.com/r/argoproj/argocd.

New Docker Repository location is https://hub.docker.com/r/realestatepilot/argocd-customtooling.

argocd secrets management is supported with additional tools:
* helm secrets
* sops
* vault

Vault Agent uses [AppRole Authentication](https://developer.hashicorp.com/vault/docs/auth/approle) and [Auto-Auth](https://developer.hashicorp.com/vault/docs/agent/autoauth/methods/approle). Vault Token is handled by Vault Agent so that the token is renewed regularly according to the TTL set.



## Usage

Parameter:
| Environment Variable | Description |
|-|-|
| VAULT_ADDR | Address of Vault Server, i.e. https://vault.organization.org:8200 |

Mounts:
|File|Content|
|-|-|
|/etc/vault.d/roleid|Approle RoleID|
|/etc/vault.d/secretid|AppRole SecretID|

## Thank you ArgoProj!

This docker is based on the fantastic work by [ArgoProj](https://argoproj.github.io/) and the really useful [helm secrets plugin](https://github.com/jkroepke/helm-secrets).