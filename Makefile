default:
	make ssl/ca.cert
	make ssl/server-a.key-cert
	make ssl/server-b.key-cert

run-mongod-a:
	mkdir -p a/data
	mongod --config mongod.a.conf

run-mongod-b:
	mkdir -p b/data
	mongod --config mongod.b.conf

rs-initiate:
	mongo --port 27017 --eval \
		'rs.initiate({_id: "examplers", version: 1, members: [{_id: 0, host: "localhost:27017"}]})'

create-root-user:
	mongo --port 27017 --eval \
		'db.createUser({user: "root", pwd: "rootpwd", roles: ["root"]})' admin

rs-add-members:
	mongo --port 27017 -u root -p rootpwd --eval 'rs.add("localhost:27117")' admin

rs-status:
	mongo --port 27017 -u root -p rootpwd --eval 'rs.status()' admin
	@echo
	@echo
	mongo --port 27117 -u root -p rootpwd --eval 'rs.status()' admin

ssl/server-%.key.password:
	echo top-secret > $@

ssl/%.key.password:
	openssl rand -base64 15 > $@

ssl/%.key: ssl/%.key.password
	openssl genrsa -aes256 -out $@ -passout file:$< 4096

.PRECIOUS: ssl/%.key.password ssl/%.key

ssl/ca.cert: ssl/ca.key
	openssl req -config ssl/openssl.conf -new -x509 -days 10000 \
		-key ssl/ca.key -passin file:ssl/ca.key.password \
		-out $@ -extensions v3_ca -subj "/O=ACME/CN=Sample CA"
	openssl x509 -noout -text -in $@

ssl/server-%.csr: ssl/server-%.key
	openssl req -config ssl/openssl.conf -new \
		-key $< -passin file:$<.password \
		-out $@ -subj "/O=ACME/CN=localhost"

ssl/server-%.cert: ssl/server-%.csr ssl/server-%.key ssl/ca.cert
	openssl x509 -req -extfile ssl/openssl.conf -days 10000 -in $< \
		-CA ssl/ca.cert -CAkey ssl/ca.key -passin file:ssl/ca.key.password \
		-set_serial `date --utc '+%s%N'` -out $@ -extensions v3_server_client
	openssl x509 -noout -text -in $@
	openssl verify -CAfile ssl/ca.cert $@

ssl/%.key-cert: ssl/%.key ssl/%.cert
	cat $^ > $@
