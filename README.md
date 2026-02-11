*Note:* This is a work in progress and subject to rapid change.

### Introduction

This is a new iteration of cluster configuration using the Argo CD Agent in managed mode. Given that
the Agent is operating in Managed mode I can no longer use my previous method of generating the
Applications with a Helm chart using sync waves. As a result there is a switch to ApplicationSets
with Progressive Sync to bulk deploy the cluster-configuration Applications per cluster.

As part of the switch I'm trying out a new system that was internally proposed by Red Hat
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

A Cluster naming convention is being used and this naming convention is used to select the
Applications being deployed on each cluster. The naming convention used is:

&lt;type&gt;-&lt;environment&gt;-&lt;location&gt;

1. *type* - this refers to the type or purpose of the cluster, at this moment there are only
two types: *hub* and *workload*.
2. *environment* - the environment the cluster represents, i.e. *prod*, *qa*, *dev*, etc
3. *location* - Where the cluster is located, in this repo there is only one location which
is my homelab and referred to as `local`

So using this system you may have clusters named as follows:

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

Would target the hub folder, similarly an overlay of `workload-prod` would target workload clusters
in production.

An overlay name of `all` targets all clusters and requires no specific configuration, i.e there
is no configuration to reflect the type, environment or specific cluster attributes (cluster_id,
wildcard subdomain, etc). If it needs specific configuration, even for a single use case, it
needs to move out of `all` and into more specific overlays.

The actual selecting of the Application is done by the cluster specific ApplicationSet using
the git path generator. For example the cluster `hub-prod-local` has the following generator
configured.

```
generators:
    - git:
        repoURL: https://github.com/gnunn-gitops/cluster-config-v2
        revision: main
        directories:
        - path: apps/**/overlays/all
        - path: apps/**/overlays/hub
        - path: apps/**/overlays/hub-prod
        - path: apps/**/overlays/hub-prod-local
```

It's important to note that you cannot have the same Application multiple times so you
cannot have an application with both an `all` overlay and a `hub` overlay for example. Addressing
this might be a fun future project using an ApplicationSet custom plugin.

Finally note that even though a specific naming convention is being used here, Organizations
wanting to try this should feel free to create a naming convention that works for them. The key
here is segmenting applications but the actual segments themselves can be changed as needed.

### Early Thoughts on this System

Here are some early personal thoughts on this new system, first the positives:

* It is much more readable then my previous version, it's super easy to find out which applications
are included on which clusters by running some simple `ls` commands.
* The ApplicationSet Progressive Sync works really well with the Argo CD Agent
* Adding or selecting new Applications is as easy as creating a new overlay, the ApplicationSet
will automatically pick it up with no additional configuration in a values file like I used to have.
* Versioning should be easier as well since you can simply set the targetRevision in the ApplicationSet versus
the separate [cluster-config-pins](https://github.com/gnunn-gitops/cluster-config-v2) repository
I had previously.

Some minor drawbacks (none of them deal-breakers):

* It's more difficult to deal with exceptions, i.e. this app needs to use ServerSideApply and this one
does not, this one needs a specific ignoreDifferences, etc. I've worked around this in the ApplicationSet
using a mix of matrix and merge generators to make dealing with it as simple as possible. However a lot
of this is just the nature of ApplicationSets, it's a trade-off between ease-of-use and flexibility.
* Part of the exception challenge is setting the `spec.destinaton.namespace` appropriately
for Argo CD Applications since folder names don't always align with namespaces. An easy solution is
to simply leave it blank but my preference is to set it as a mitigation for someone forgetting to set it
at the Kustomize level. For now I'm leveraging the exception mechanism in the first point to deal with it.
* In larger fleets of clusters creating the cluster specific overlays might get a bit much. In my previous
version I used an Argo CD CMP plugin that could dynamically replace standard cluster values like subdomain
and cluster_id, this could be reintroduced to eliminate some common patching requirements and mitigate
some of the need for more specific overlays.

### Credits

Thanks to Ben Colby-Sexton, Tom Stockwell, Jack Adolph and Stephen Leahy for proposing the original
version of this repo structure.
