#!/bin/bash

# Generate private key (X25519 private key)
openssl genpkey -algorithm X25519 -out /tmp/private.pem

# Extract public key from private key
openssl pkey -in /tmp/private.pem -pubout -out /tmp/public.pem

# Public key - extract the key portion and remove headers
public_key=$(openssl pkey -in /tmp/public.pem -pubin -outform DER | tail -c 32 | base64)
echo "Public key: $public_key"

# Convert from PEM to the raw base64 format WireGuard expects
# Private key - extract the key portion and remove headers
private_key=$(openssl pkey -in /tmp/private.pem -outform DER | tail -c 32 | base64)
echo "Private key: $private_key"
