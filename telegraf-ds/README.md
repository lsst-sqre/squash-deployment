# Telegraf DaemonSet

[Telegraf](https://github.com/influxdata/telegraf) is a plugin-driven server agent written by the folks over at [InfluxData](https://influxdata.com) for collecting & reporting metrics. This chart runs a DaemonSet of Telegraf instances to collect host level metrics for your cluster.

## TL;DR

```console
$ helm install ./telegraf-ds
```

## Introduction

This chart bootstraps a `telegraf-ds` deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Kubernetes 1.6  + with Beta APIs enabled

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release ./telegraf-ds
```

The command deploys a Telegraf daemonset on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section as well as the [values.yaml](/values.yaml) file lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Telegraf Configuration

This chart deploys the following by default:

- `telegraf-ds` running in a daemonset with the following plugins enabled
  * [`docker`](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/docker)
  * [`kubernetes`](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/kubernetes)
