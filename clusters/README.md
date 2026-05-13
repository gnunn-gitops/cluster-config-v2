This helm chart generates an ApplicationSet that bootstraps a single
cluster. It uses the folder structure under apps (00-core, 10-config, 20-operators, etc)
with ProgressiveSync to deploy applications in order. This is needed to ensure
that core services like cert-manager and external-secrets are available for
use in subsequent applications.
