This installs the core, i.e. the root, External Secrets Operator (ESO) secret and ClusterSecretStore
on every cluster. This secrets are read from the namespace `core-secrets` but are not stored in
git for obvious reasons. The resources in `resources/core-secrets` are installed manually
on the Hub prior to manually installing RHACM.

Note there is a eventual consistency at play here in the sense that GitOps will install
and manage the External Secrets Operator and once the `external-secrets` namespace
is available this policy will copy the core secret into that namespace. Each cluster
gets its own specific token as I'm leveraging Doppler's project inheritance
mechanism to separate shared secrets from secrets that only required on a specific
cluster.
