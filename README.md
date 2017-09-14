# squash-deployment
Manage the deployment of the squash microservices.


## SQuaSH microservices deployment

[squash-deployment](https://github.com/lsst-sqre/squash-deployment) will clone the repositories for the individual squash microservices, set the appropriate 
namespace and context, create the secrets and deploy the microservices in the right order.

### Deployment namespace

A Kubernetes _namespace_ provide a scope for Pods, Services, and Deployments in the cluster.
In the current implementation we have two namespaces `development` or `production`.

Namespaces are also used to define a context in which the `kubectl` client works.

Use the following to create a `development` namespace and switch to the right context:
```
NAMESPACE=development make context
```

### Create the `tls-certs` secret

TLS termination is implemented in the [squash-api](https://github.com/lsst-sqre/squash-api), [squash-bokeh](https://github.com/lsst-sqre/squash-bokeh) and the [squash-dash](https://github.com/lsst-sqre/squash-dash) microservices to secure traffic on `*.lsst.codes` domain. 

Download the `lsst-certs.git` repo from the [lsst-square](https://www.dropbox.com/home/lsst-sqre) Dropbox folder, it has the SSL key and certificates. Use the following to create the `tls-certs` secret.
 
```
  make tls-certs
```

### SQuaSH DB

[squash-db](https://github.com/lsst-sqre/squash-db) provides a persistent installation of MariaDB on Kubernetes for SQuaSH

```
make squash-db
```

![SQuaSH db microservice](figs/squash-db.png)

### SQuaSH API

The [squash-api](https://github.com/lsst-sqre/squash-api) connects the [squash-db](https://github.com/lsst-sqre/squash-db), the [squash-bokeh](https://github.com/lsst-sqre/squash-bokeh) and the [squash-dash](https://github.com/lsst-sqre/squash-dash) microservices.

```
  make squash-api 
```

![SQuaSH DB and the API microservices](figs/squash-db-api.png)


### SQuaSH Bokeh
The [squash-bokeh](https://github.com/lsst-sqre/squash-bokeh) provides a Bokeh server and host the SQuaSH bokeh apps. Bokeh apps can be embedded in the [squash-dash](https://github.com/lsst-sqre/squash-dash) frontend or in the JupiterLab environment.
 
```
  make squash-bokeh
```

![SQuaSH DB, API and the Bokeh microservices](figs/squash-db-api-bokeh.png)


### SQuaSH Dash
The [squash-dash](https://github.com/lsst-sqre/squash-dash) is a frontend interface to embed the SQuaSH bokeh apps and display statistics from the SQuaSH API. 

```
  make squash-dash
```

![SQuaSH DB, API, Bokeh and the Dashboard microservices](figs/squash-deployment.png)


## Environment variables
The following environment variables are used by the deployment:

- SQUASH_DB_HOST
- SQUASH_DB_PASSWORD
- SQUASH_API_HOST
- SQUASH_API_URL
- SQUASH_API_DEBUG
- SQUASH_BOKEH_HOST
- SQUASH_BOKEH_PORT
- SQUASH_BOKEH_URL
- SQUASH_DASH_HOST

