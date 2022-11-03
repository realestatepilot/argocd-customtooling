pid_file = "./pidfile"

auto_auth {
  method {
    type = "approle"

    config = {
      role_id_file_path = "/etc/vault.d/roleid"
      secret_id_file_path = "/etc/vault.d/secretid"
      remove_secret_id_file_after_reading = false
    }
    min_backoff = "10s"
    max_backoff = "5m"
    exit_on_err =  false
  }

  sink {
    type = "file"

    config = {
      path = "/home/argocd/.vault_token"
    }
  }
}