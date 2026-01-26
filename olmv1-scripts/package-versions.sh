# echo "Inspecting package ${1}"

# opm render registry.redhat.io/redhat/redhat-operator-index:v4.20 \
#   | jq -s '.[] | select( .schema == "olm.package")| select( .name == "'"${1}"'")'

echo "Channels"

opm render registry.redhat.io/redhat/redhat-operator-index:v4.20 \
  | jq -s '.[] | select( .schema == "olm.channel" ) | select( .package == "'"${1}"'") | .name'

echo "Bundles"

opm render registry.redhat.io/redhat/redhat-operator-index:v4.20 | \
  jq -cs '.[] | select( .schema == "olm.bundle" ) | select( .package == "'"${1}"'") | {"name":.name, "image":.image}'
