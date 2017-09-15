NAMESPACE_TEMPLATE = kubernetes/namespace-template.yaml
NAMESPACE_CONFIG = kubernetes/namespace.yaml
REPLACE = ./kubernetes/replace.sh

# Downloaded from the `lsst-square` Dropbox folder
LSST_CERTS_REPO = lsst-certs.git
LSST_CERTS_YEAR = 2017

# Keys and certificates used in nginx config
SSL_KEY = lsst.codes.key
SSL_CERT = lsst.codes_chain.pem

# SSL config also requires a dhparam file
SSL_DH = dhparam.pem

# Output dirs
LSST_CERTS_DIR = lsst-certs
TLS_DIR = tls

# SQuaSH repos
SQUASH_DB_REPO = https://github.com/lsst-sqre/squash-db.git
SQUASH_API_REPO = https://github.com/lsst-sqre/squash-api.git
SQUASH_BOKEH_REPO = https://github.com/lsst-sqre/squash-bokeh.git
SQUASH_DASH_REPO = https://github.com/lsst-sqre/squash-dash.git

DELETE_CONTEXT = $(shell read -p "All previous Pods, Services, and Deployments \
in the \"${NAMESPACE}\" namespace will be destroyed. Are you sure? [y/n]:" answer; echo $$answer)

# Find cluster and user from the current context to set the new context

CURRENT_CONTEXT = $(shell kubectl config current-context)

CONTEXT_USER = $(shell kubectl config view -o jsonpath --template="{.contexts[?(@.name == \"$(CURRENT_CONTEXT)\")].context.user}")
CONTEXT_CLUSTER = $(shell kubectl config view -o jsonpath --template="{.contexts[?(@.name == \"$(CURRENT_CONTEXT)\")].context.cluster}")

context: check-namespace
	@$(REPLACE) $(NAMESPACE_TEMPLATE) $(NAMESPACE_CONFIG)
	@if [ "$(DELETE_CONTEXT)" = "y" ]; \
	then kubectl delete --ignore-not-found -f $(NAMESPACE_CONFIG); \
	else echo "Exiting..."; \
	     exit 1; \
	fi
	@sleep 10
	kubectl create -f $(NAMESPACE_CONFIG)
	kubectl config set-context ${NAMESPACE} --namespace=${NAMESPACE} --cluster=$(CONTEXT_CLUSTER) --user=$(CONTEXT_USER)
	kubectl config use-context ${NAMESPACE}


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

squash-db:
	git clone $(SQUASH_DB_REPO)
	@echo "Enter a password for the SQuaSH DB:"
	@read MYSQL_PASSWD
	@echo $MYSQL_PASSWD > squash-db/passwd.txt
	$(MAKE) deployment -C squash-db

squash-api:
	git clone $(SQUASH_API_REPO)
	TAG=latest $(MAKE) deployment -C squash-api

squash-bokeh:
	git clone $(SQUASH_BOKEH_REPO)
	TAG=latest $(MAKE) deployment -C squash-bokeh

squash-dash:
	git clone $(SQUASH_DASH_REPO)
	TAG=latest $(MAKE) deployment -C squash-dash

.PHONY: clean

clean:
	rm -rf $(LSST_CERTS_DIR)
	rm -rf $(TLS_DIR)
	rm -rf squash-db
	rm -rf suqash-api

check-namespace:
	@if [ -z ${NAMESPACE} ]; \
	then echo "Error: NAMESPACE is undefined."; \
	     exit 1; \
	fi
