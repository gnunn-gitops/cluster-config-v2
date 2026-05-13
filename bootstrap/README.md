This uses an ApplicationSet to manage the bootstrap of all Argo CD Agent clusters. It generates
an application per cluster that deploys the ApplicationSet defined in the Helm chart in clusters.

It uses ProgressiveSync to so that clusters are evaluated in order of the environment
(lab > dev > stage > prod).
