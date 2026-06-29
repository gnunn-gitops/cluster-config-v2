This policy is used to bootstrap the Argo CD Agent onto a cluster. It works with the
argocd-agent-registration policy in the sense that this policy installs the PKI and infra
needed on the remote agent while the argocd-agent-registration policy deploys the infra
needed on the Control Plane.
