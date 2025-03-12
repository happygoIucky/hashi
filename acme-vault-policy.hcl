# Vault admin policy
# Mount the database secret engine
path "sys/mounts/database" {
  capabilities = [ "create", "update", "delete" ]
}

# Configure the database secrets engine and create roles
path "database/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}

# Database read-only policy
# Read creds from the database secrets engine readonly role
path "database/creds/readonly" {
  capabilities = [ "read" ]
}