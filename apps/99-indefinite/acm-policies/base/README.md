This is a set of RHACM policies to manage the bootstrapping of the
Argo CD Agent onto remote clusters. It manages the provisioning of
the per Agent resources and PKI on the control plane cluster
as well as the remote cluster where the Agent is being installed.

* `gitops-subscription`: Deploys the OpenShift GitOps subscription onto clusters
* `argocd-agent-registration`: Manages the registration of the Argo CD Agent on the Control Plane cluster
* `argocd-agent`: Bootstraps the agent on the remote cluster.

Note that the remote cluster requires the PKI generated in `argocd-agent-registration`, no PKI is generated
on remote clusters. Instead we use RHACM policies to copy the PKI secrets to the remote clusters.
