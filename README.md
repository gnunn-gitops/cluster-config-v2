### Introduction

This is a new iteration of cluster configuration using the Argo CD Agent in managed mode. Given that
the Agent is operating in Managed mode I can no longer use my previous method of generating the
Applications with a Helm chart using sync waves. As a result there is a switch to ApplicationSets
with Progressive Sync to bulk deploy the cluster-configuration Applications per cluster.

As part of the switch I'm trying out a modified version of system that was internally proposed by Red Hat
Consultants (see credits below). My original system was very DRY (Don't Repeat Yourself) but this
came at the expense of readability. This new system is more readable but in larger environments
(i.e. 100s or 1000s of clusters) managing all of the overlays may become onerous, more on that
below.

This system is leveraging Kustomize overlays to manage the selecting of Applications on a
per cluster basis as the next section will cover.

### Repository Structure

The structure of this repository is simpler then the previous [version](https://github.com/gnunn-gitops/cluster-config)
and has two primary folders:

1. *apps* - This is where all of the applications that are deployed across the clusters reside
2. *clusters* - This is the ApplicationSets for each individual cluster, at some point this
will likely be migrated to a generic RHACM ConfigurationPolicy alongside the existing
`agent-registration` policy.
3. *bootstrap* - This bootstraps the per-cluster ApplicationSet in *cluster* across all
Argo CD Agent clusters that have been registered.

### Cluster Naming Convention

A Cluster naming convention is being used and this is used to select the
Applications being deployed on each cluster. The naming convention used is:

```
<type>-<environment>-<location>
```

1. *type* - this refers to the type or purpose of the cluster, at this moment there are only
two types: *hub* and *workload*.
2. *environment* - the environment the cluster represents, i.e. *prod*, *qa*, *dev*, etc
3. *location* - Where the cluster is located, in this repo there is only one location which is my homelab and referred to as `local` but in the future there could be some
in `aws` for example.

So using this system there may be clusters named as follows:

* `hub-prod-local`
* `workload-qa-aws`
* etc

These segments are used for grouping purposes to select the Applications placed on each
cluster. These segments are created by naming overlays to match the segment, so for example
a folder structure of this:

```
acm-operator
   - base
   - overlays
     - hub
```

With an overlay of `hub` this would target hub clusters, similarly an overlay of
`workload-prod` would target workload clusters in production.

An overlay name of `all` is used for Applications which target all clusters and require
no specific configuration, i.e there is no configuration to reflect the type, environment
or specific cluster attributes (cluster_id, wildcard subdomain, etc). If it needs specific
configuration, even for a single use case, it needs to move out of `all` and into more
specific overlays.

The actual selecting of the Application is done by the cluster specific ApplicationSet using
the git path generator. For example the cluster `hub-prod-local` has the following generator
configured.

```
generators:
    - git:
        repoURL: https://github.com/gnunn-gitops/cluster-config-v2
        revision: main
        files:
        - path: apps/**/**/overlays/all/app-config.yaml
        - path: apps/**/**/overlays/{{ $clusterType }}/app-config.yaml
        - path: apps/**/**/overlays/{{ $clusterType }}-{{ $clusterEnv }}/app-config.yaml
        - path: apps/**/**/overlays/{{ .Values.clusterName }}/app-config.yaml
```

It's important to note that you cannot have the same Application generated multiple times so you
cannot have an application with both an `all` overlay and a `hub` overlay for example. Addressing
this might be a fun future project using an ApplicationSet custom plugin.

Finally note that even though a specific naming convention is being used here, Organizations
wanting to try this system should feel free to create a naming convention that works for them. The key
here is segmenting applications but what the actual segments themselves are can be changed as needed.

### Reducing Overlays

OpenShift typically has some static information (subdomain, base domain, clusterID, infrastructureID) that
needs to be referenced in cluster configuration. One option is to simply handle this in kustomize
with overlays and with a smaller number of clusters this works fine. However when dealing
with large fleets of clusters this can become onerous.

There are typically a few different ways of handling this:

1. Live with the pain and manually define the overlays as needed. This is burdensome and error prone.
2. Use external automation, for example Ansible, to generate the required overlays in git
3. Use RHACM ConfigurationPolicy to communicate these values to Argo CD via some mechanism

Since I'm already using RHACM ConfigurationPolicy to manage the Argo CD Agent cluster secrets on the Hub
I've opted to go with 3.

When a new Agent is registered RHACM automatically includes this static information as annotations
in the cluster secret which in turn can be used by the ApplicationSet cluster generator. With
the git file generator a parameter `clusterSettings` can be set to true and if present the ApplicationSet
will include a kustomize patch in the generated Application to update a ConfigMap with these values.

In kustomize, the Replacements feature is then used to pull these values from the ConfigMap and patch
them where they need to go.

### git file versus directory generator

For the per-cluster ApplicationSet I've opted to use the file generator. I found that I have Applications
where either specific Argo CD Application configuration is required, the destination namespace cannot
be derived from the path, etc.

The other benefit is that when working on a new Application the AppSet will not pick it up until I have
added the `app-config.yaml` file. This is convenient when trying to develop new functionality iteratively.

Currently the following parameters are supported in `app-config.yaml`:

* namespace: Used for the destination namespace in the Application, normally derived from the path.
* targetRevision: Overrides the targetRevision on a per-Application basis. Can be useful when either
the Application has to use the latest and greatest or for troubleshooting issues.
* annotations: Add additional annotations to the Application, useful for enabling specific Argo CD behaviors.
* syncOptions: Specific syncOptions, such as ServerSideApply, that may need to be enabled for Applications.

### Early Thoughts on this System

Here are some very early personal thoughts on this new system, first the positives:

* It is much more readable then my previous version, it's super easy to find out which applications
are included on which clusters by running some simple `ls` commands.
* The ApplicationSet Progressive Sync works really well with the Argo CD Agent in Managed mode.
* Adding or selecting new Applications is as easy as creating a new overlay, the ApplicationSet
will automatically pick it up with no additional configuration required in the values file like I used to have.
* Versioning should be easier as well since you can simply set the targetRevision in the ApplicationSet versus
the separate [cluster-config-pins](https://github.com/gnunn-gitops/cluster-config-v2) repository
I had previously.

Some minor drawbacks (none of them deal-breakers):

* It's more difficult to deal with exceptions, i.e. this app needs to use ServerSideApply and this one
does not, this one needs a specific ignoreDifferences, etc. I've worked around this by including
exceptions as parameters in the `app-config.yaml` picked up by the git files generator. The ApplicationSet
then uses a `templatePatch` to set these appropriately.

### Managing the Argo CD Agent

The Argo CD Agent, when registering a new cluster, requires some configuration both on the Control
Plane (i.e. the Hub) as well as the target cluster. In the future RHACM will have an add-on available
to manage this but for now I've created some policies to handle this automatically.

*NOTE*: These policies are not supported by Red Hat and it is an interim measure until full RHACM
support is available through the Add-On. There is no intent to productize these policies in the
future.

Note that PKI is required for the Argo CD Agent in order to manage the Mutual-TLS certificates required
on the Control Plane where the Principal resides and on the target cluster where the Agent is residing. These
policies use `cert-manager` to handle this and deploy an `Issuer` with a self-signed certificate
to generate the certs. As new Agent clusters are registered, the policies automatically create
new cluster specific certificates for the Control Plane and the Agent.

There are three policies being used:

* *gitops-subscription*. This installs the OpenShift GitOps subscription on a cluster if it has either
the `argocd-agent` or the `argocd-agent-control-plane` label.
* *argocd-agent-registration*. This creates the certificates and the cluster secret needed to register
the new agent on the control plane. It picks up any ManagedClusters with the label `argocd-agent: <name>`
and creates the needed resources on the Control Plane.
* *argocd-agent*. This deploys the agent on the target cluster and copies the required TLS certificates
from the Control Plane to the target cluster. Only the Control Plane requires `cert-manager`, the workload
clusters do not.

The Argo CD Agent is using destination mapping, both the control plane and the agent are installed in the
`argocd` namespace. On the control plane the hybrid architecture is used so an application-controller is deployed
to manage local applications that target the control plane cluster.

To support the hybrid architecture but have the bootstrap ApplicationSet recognize the control plane
cluster, the `argocd-agent-registration` policy automatically creates a cluster secret with the appropriate
labels and name as an alternative to the standard `in-cluster`.

Finally note that these policies are not generic, it's an example of how things can be done but it's not
something that can just be ripped out and dropped into a new Hub cluster as is. Some adjustments will
be required.

### Versioning

To manage the version of resources that are deployed to the cluster the policies add a `targetRevision`
annotation to each cluster secret and the `bootstrap` ApplicationSet passes this as a Helm parameter
to the per cluster ApplicationSet.

The value for targetRevision is sourced from a [ConfigMap](https://github.com/gnunn-gitops/cluster-config-v2/blob/main/apps/99-indefinite/managed-clusters/base/cluster-versions.yaml)
based on the cluster environment (i.e. lab, dev, stage or prod) but can be overridden
by either setting the targetRevision on a ManagedCluster or including it as a parameter in app-config.yaml. This
ConfigMap is only deployed on the Hub cluster where the RHACM agent policies can lookup the values from this
ConfigMap and add it as an annotation to the cluster secrets.

The Application where this configmap is managed always uses HEAD as the targetRevision, set in
[app-config.yaml](https://github.com/gnunn-gitops/cluster-config-v2/blob/main/apps/99-indefinite/managed-clusters/overlays/hub-prod-local/app-config.yaml).

The code for this is a bit convoluted for my taste but it's a trade-off between more complex code and simpler
operational maintenance.

Longer term, when OpenShift GitOps includes the GitOps Promoter as a preview, I'll look at switching this over to use that.

### Credits

Thanks to Ben Colby-Sexton, Tom Stockwell, Jack Adolph and Stephen Leahy for proposing the original
version of this repository structure.
