#!/bin/bash

while :
do 
  if ! pgrep -x "vault" > /dev/null
  then
    vault agent -config /etc/vault.d/vault.hcl & 
  fi
  sleep 60
done