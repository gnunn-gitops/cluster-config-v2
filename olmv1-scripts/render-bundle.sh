opm render \
  registry.redhat.io/redhat/redhat-operator-index:v4.20 \
  | jq -cs '[.[] | select(.schema == "olm.bundle" and (.properties[] | select(.type == "olm.csv.metadata").value.installModes[] | select(.type == "AllNamespaces" and .supported == true)) and .spec.webhookdefinitions == null) | .package] | unique[]'
