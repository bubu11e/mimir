---
title: "(Optional) Ruler"
description: ""
weight: 20
---

# (Optional) Ruler

The ruler is an optional component that evaluates PromQL expressions defined in recording and alerting rules.
Each tenant has a set of recording and alerting rules and can group those rules into namespaces.

## Recording rules

The ruler evaluates the expressions in the recording rules at regular intervals and writes the results back to the ingesters.
The ruler has a built-in querier that evaluates the PromQL expressions and a built-in distributor, so that it can write directly to the ingesters.
Configuration of the built-in querier and distributor uses their respective configuration parameters:

- [Querier]({{< relref "../../configuring/reference-configuration-parameters.md#querier" >}})
- [Distributor]({{< relref "../../configuring/reference-configuration-parameters.md#distributor" >}})

## Alerting rules

The ruler evaluates the expressions in alerting rules at regular intervals and if the result includes any series, the alert becomes active.
If an alerting rule has a defined `for` duration, it enters the **PENDING** (`pending`) state.
After the alert has been active for the entire `for` duration, it enters the **FIRING** (`firing`) state.
The ruler then notifies Alertmanagers of any **FIRING** (`firing`) alerts.

Configure the addresses of Alertmanagers with the `-ruler.alertmanager-url` flag, which supports the DNS service discovery format.
For more information about DNS service discovery, refer to [Supported discovery modes]({{< relref "../../configuring/about-dns-service-discovery.md" >}}).

## Sharding

The ruler supports multi-tenancy and horizontal scalability.
To achieve horizontal scalability, the ruler shards the execution of rules by rule groups.
Ruler replicas form their own [hash ring]({{< relref "../hash-ring.md" >}}) stored in the [KV store]({{< relref "../key-value-store.md" >}}) to divide the work of the executing rules.

To configure the rulers' hash ring, refer to [configuring hash rings]({{< relref "../../operating/configuring-hash-rings.md" >}}).

## HTTP configuration API

The ruler HTTP configuration API enables tenants to create, update, and delete rule groups.
For a complete list of endpoints and example requests, refer to [ruler]({{< relref "../../reference-http-api/_index.md#ruler" >}}).

## State

The ruler uses the backend configured via `-ruler-storage.backend`.
The ruler supports the following backends:

- [Amazon S3](https://aws.amazon.com/s3): `-ruler-storage.backend=s3`
- [Google Cloud Storage](https://cloud.google.com/storage/): `-ruler-storage.backend=gcs`
- [Microsoft Azure Storage](https://azure.microsoft.com/en-us/services/storage/): `-ruler-storage.backend=azure`
- [OpenStack Swift](https://wiki.openstack.org/wiki/Swift): `-ruler-storage.backend=swift`
- [Local storage]({{< relref "#local-storage" >}}): `-ruler-storage.backend=local`

### Local storage

The `local` storage backend reads [Prometheus recording rules](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/) from the local filesystem.

> **Note:** Local storage is a read-only backend that does not support the creation and deletion of rules through the [Configuration API]({{< relref "#http-configuration-api" >}}).

When all rulers have the same rule files, local storage supports ruler sharding.
To facilitate sharding in Kubernetes, mount a [Kubernetes ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) into every ruler pod.

The following example shows a local storage definition:

```
-ruler-storage.backend=local
-ruler-storage.local.directory=/tmp/rules
```

The ruler looks for tenant rules in the `/tmp/rules/<TENANT ID>` directory.
The ruler requires rule files to be in the [Prometheus format](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/#recording-rules).