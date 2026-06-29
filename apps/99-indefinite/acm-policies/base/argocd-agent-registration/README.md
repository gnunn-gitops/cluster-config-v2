This policy manages Argo CD infrastructure on the Control Plane. Note that this policy only deploys
the dynamic Agent components, namely it:

* Creates cert-manager certificates for the principal and agent for each ManagedCluster
* Creates a specific cluster AppProject that is used to deploy cluster-config (note this is not used by tenants)
* Creates an Agent cluster secret that pulls in the PKI for the Certificates that it deployed earlier

The policy looks for ManagedClusters in RHACM that have the label `argocd-agent: <cluster-name>` and creates
these per-Agent resources on the control plane based off that label.

Note that it also deploys a local cluster-secret for the control plane which uses the same naming convention and
additional labels and secrets placed.

See the main readme file for the details on the cluster naming convention.
