#!/bin/bash

FILE=/etc/vault.d/roleid
if [ -f "$FILE" ]; then
	/home/argocd/vault-restart.sh >> /proc/1/fd/1 2>&1
fi

# If we're started as PID 1, we should wrap command execution through tini to
# prevent leakage of orphaned processes ("zombies").
if test "$$" = "1"; then
	exec tini -- $@
else
	exec "$@"
fi