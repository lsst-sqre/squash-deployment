all:
# Downloaded from the `lsst-square` Dropbox folder
LSST_CERTS = lsst-certs.git
LSST_CERTS_YEAR = 2017

# Keys and certificates used in nginx config
SSL_KEY = lsst.codes.key
SSL_CERT = lsst.codes_chain.pem
SSL_DH = dhparam.pem

tls-certs: $(LSST_CERTS)
	@echo "Creating tls-certs secret..."

	mkdir -p lsst-certs
	cd lsst-certs; git init; git remote add origin ../$(LSST_CERTS); git pull origin master
	mkdir -p tls
	cp lsst-certs/lsst.codes/$(LSST_CERTS_YEAR)/$(SSL_KEY) tls/
	cp lsst-certs/lsst.codes/$(LSST_CERTS_YEAR)/$(SSL_CERT) tls/

	# SSL config also requires a dhparam file
	openssl dhparam -out tls/$(SSL_DH) 2048

	kubectl delete --ignore-not-found=true secrets tls-certs
	kubectl create secret generic tls-certs --from-file=tls/

clean:
	rm -rf lsst-certs
	rm -rf tls

