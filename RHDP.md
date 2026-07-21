1. Apply the GitOps operator, note this disables the default instance.
   `oc apply -k apps/20-operators/openshift-gitops-operator/overlays/workload-prod-rhdp/`

2. Apply the GitOps instance (this will create Argo CD in `argocd` namespace)
   `oc apply -k apps/99-indefinite/openshift-gitops/overlays/workload-prod-rhdp/`

3. Create a cluster-admins group and add the `admin` user to it:
   `oc adm groups new cluster-admins admin`

4. Create an Argo CD cluster secret, update the baseDomain and subdomain for your URLs:

```
apiVersion: v1
kind: Secret
metadata:
  annotations:
    baseDomain: 'cluster-9svs7.dyn.redhatworkshops.io'
    subdomain: 'apps.cluster-9svs7.dyn.redhatworkshops.io'
    targetRevision: 'rhdp'
  name: workload-prod-rhdp
  namespace: argocd
  labels:
    app.kubernetes.io/name: workload-prod-rhdp
    argocd.argoproj.io/secret-type: cluster
    env: prod
    region: rhdp
    type: workload
stringData:
  name: workload-prod-rhdp
  server: https://kubernetes.default.svc
  config: |
    {
      "tlsClientConfig": {
        "insecure": false
      }
    }
```

5. Apply the bootstrap ApplicationSet
   `oc apply -k ./bootstrap/base`
