.PHONY: deploy
deploy:
	oc new-project vhostnet || oc project vhostnet
	oc adm policy add-scc-to-user privileged -z default
	# oc adm policy add-role-to-user cluster-reader -z default
	bash privileged.sh vhostnet
	oc apply -f sriovnetwork.yaml
	oc create configmap --from-file=vhostnet.sh=vhostnet.sh entrypoint
	cat vhostnet.yaml | oc apply -f -

.PHONY: undeploy
undeploy:
	oc project default
	oc delete project vhostnet
