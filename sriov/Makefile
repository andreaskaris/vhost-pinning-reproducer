.PHONY: install-operator
install-operator:
	oc apply -f sriov-install.yaml
	oc label $(oc get nodes -o name) feature.node.kubernetes.io/network-sriov.capable="true"

.PHONY: create-network-node-policy
create-network-node-policy:
	oc apply -f sriov-network-node-policy.yaml

.PHONY: sleep
sleep:
	sleep 300

.PHONY: install
install: install-operator sleep create-network-node-policy

.PHONY: uninstall
uninstall:
	oc delete -f sriov-network-node-policy.yaml
	oc delete -f sriov-install.yaml
