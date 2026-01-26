export CLUSTER_SERVICE_VERSION=$(ls ./tmp/manifests/*clusterserviceversion.yaml)

echo $CLUSTER_SERVICE_VERSION

cat $CLUSTER_SERVICE_VERSION | yq --yaml-output .spec.install.spec.clusterPermissions[0].rules
