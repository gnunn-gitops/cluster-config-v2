On OpenShift Ingress doesn't place anything in .status.loadbalancer resulting
in the default health check being stuck in Progressing. In this custom
health check as long as the .status.loadbalancer exists it's considered
healthy.
