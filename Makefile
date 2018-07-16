SHELL := /bin/bash

# Create namespace for deployment
NAMESPACE_TEMPLATE = kubernetes/namespace-template.yaml
NAMESPACE_CONFIG = kubernetes/namespace.yaml
REPLACE = ./kubernetes/replace.sh

REMOVE_CONTEXT = $(shell read -p "All previous Pods, Services, and Deployments \
in the \"${NAMESPACE}\" namespace will be destroyed. Are you sure? [y/n]:" answer; echo $$answer)

# Find cluster and user from the current context to set the new context
CURRENT_CONTEXT = $(shell kubectl config current-context)
CONTEXT_USER = $(shell kubectl config view -o jsonpath --template="{.contexts[?(@.name == \"$(CURRENT_CONTEXT)\")].context.user}")
CONTEXT_CLUSTER = $(shell kubectl config view -o jsonpath --template="{.contexts[?(@.name == \"$(CURRENT_CONTEXT)\")].context.cluster}")

# Find the cluster and user from a previously created context (by construction the context name = namespace)
EXISTING_CONTEXT_USER = $(shell kubectl config view -o jsonpath --template="{.contexts[?(@.name == \"${NAMESPACE}\")].context.user}")
EXISTING_CONTEXT_CLUSTER = $(shell kubectl config view -o jsonpath --template="{.contexts[?(@.name == \"${NAMESPACE}\")].context.cluster}")

namespace: check-namespace
	@$(REPLACE) $(NAMESPACE_TEMPLATE) $(NAMESPACE_CONFIG)
	kubectl create -f $(NAMESPACE_CONFIG)
	kubectl config set-context ${NAMESPACE} --namespace=${NAMESPACE} --cluster=$(CONTEXT_CLUSTER) --user=$(CONTEXT_USER)
	kubectl config use-context ${NAMESPACE}

switch-namespace: check-namespace
	kubectl config set-context ${NAMESPACE} --namespace=${NAMESPACE} --cluster=$(EXISTING_CONTEXT_CLUSTER) --user=$(EXISTING_CONTEXT_USER)
	kubectl config use-context ${NAMESPACE}

remove-namespace: check-namespace
	@if [ "$(REMOVE_CONTEXT)" = "y" ]; \
	then kubectl delete namespace ${NAMESPACE}; \
	else echo "Exiting..."; \
	     exit 1; \
	fi

# Create Kubernetes tls-certs secret

# LSST_CERTS_REPO is downloaded from the `lsst-square` Dropbox folder
LSST_CERTS_REPO = lsst-certs.git
LSST_CERTS_YEAR = 2018

# Keys and certificates used in nginx config
SSL_KEY = lsst.codes.key
SSL_CERT = lsst.codes_chain.pem

# SSL config also requires a dhparam file
SSL_DH = dhparam.pem

# Output dirs
LSST_CERTS_DIR = lsst-certs
TLS_DIR = tls

$(TLS_DIR)/$(SSL_DH):
	@mkdir -p $(TLS_DIR)
	openssl dhparam -out $(TLS_DIR)/$(SSL_DH) 2048

.PHONY: tls-certs
tls-certs: $(TLS_DIR)/$(SSL_DH)
	@echo "Creating tls-certs secret..."

	@mkdir -p $(LSST_CERTS_DIR)
	@cd $(LSST_CERTS_DIR); git init; git remote add origin ../$(LSST_CERTS_REPO); git pull origin master

	cp lsst-certs/lsst.codes/$(LSST_CERTS_YEAR)/$(SSL_KEY) $(TLS_DIR)
	cp lsst-certs/lsst.codes/$(LSST_CERTS_YEAR)/$(SSL_CERT) $(TLS_DIR)
	kubectl delete --ignore-not-found=true secrets tls-certs
	kubectl create secret generic tls-certs --from-file=$(TLS_DIR)



REPO_URL = https://github.com/lsst-sqre/${SQUASH_SERVICE}.git

clone: check-service
	git clone $(REPO_URL)

deployment:
	TAG=latest $(MAKE) service deployment -C ${SQUASH_SERVICE}

# Create AWS route53 resources
TERRAFORM = ./terraform/bin/terraform

$(TERRAFORM):
	$(MAKE) -C terraform

EXTERNAL_IP = $(shell kubectl get service ${SQUASH_SERVICE} -o jsonpath --template='{.status.loadBalancer.ingress[0].ip}')

# By construction the context name is the same as the namespace name, see above.

name: $(TERRAFORM) check-service check-namespace check-aws-creds
	source terraform/tf_env.sh ${SQUASH_SERVICE} $(CURRENT_CONTEXT) $(EXTERNAL_IP); \
	$(TERRAFORM) apply -state=terraform/${SQUASH_SERVICE}-${NAMESPACE}.tfstate terraform/dns

remove-name: $(TERRAFORM) check-service check-namespace check-aws-creds
	source terraform/tf_env.sh; \
	$(TERRAFORM) destroy -state=terraform/${SQUASH_SERVICE}-${NAMESPACE}.tfstate

check-service:
	@if [ -z ${SQUASH_SERVICE} ]; \
	then echo "Error: SQUASH_SERVICE is undefined."; \
       exit 1; \
    fi

check-aws-creds:
	@if [ -z ${AWS_ACCESS_KEY_ID} ]; \
	then echo "Error: AWS_ACCESS_KEY_ID is undefined."; \
       exit 1; \
    fi
	@if [ -z ${AWS_SECRET_ACCESS_KEY} ]; \
    then echo "Error: AWS_SECRET_ACCESS_KEY is undefined."; \
       exit 1; \
    fi

check-namespace:
	@if [ -z ${NAMESPACE} ]; \
	then echo "Error: NAMESPACE is undefined."; \
	     exit 1; \
	fi

clean:
	rm -rf $(LSST_CERTS_DIR)
	rm -rf $(TLS_DIR)
	rm -rf $(SQUASH_DB_PASSWD)
