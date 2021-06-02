namespace "*" {
  policy       = "read"
  capabilities = ["read-logs"]
}

agent {
  policy = "read"
}

operator {
  policy = "read"
}

quota {
  policy = "read"
}

node {
  policy = "read"
}

host_volume "*" {
  policy = "read"
}

plugin {
  policy = "read"
}