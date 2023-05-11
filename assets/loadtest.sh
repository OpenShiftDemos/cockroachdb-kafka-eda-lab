#!/bin/bash

# assumes you are logged in as cluster admin

# establish the sequence of users
THE_SEQUENCE=$(seq 6 62)

# determine the gitea endpoint
GITEA_ENDPOINT=$(oc get route -n gitea gitea -o jsonpath='{.spec.host}')

# put the repo somewhere
git clone https://$GITEA_ENDPOINT/user1/cockroach-kafka-eda /tmp/cockroach-kafka-eda

for i in $THE_SEQUENCE
do
	oc new-app -n user$i-eda quay.io/openshiftdemos/cockroach-kafka-eda-fruit-node:latest
	oc expose -n user$i-eda svc/cockroach-kafka-eda-fruit-node
	sed "s/userX/user$i/" dbaas-instance.yaml | oc create -n user$i-eda -f -
	sed "s/userX/user$i/" kafkatopic.yaml | oc create -n user$i-eda -f -
	oc new-app -n user$i-eda -e TOPIC_NAME=user$i-table-changes quay.io/openshiftdemos/python-kafka-producer:latest
	oc new-app -n user$i-eda -e TOPIC_NAME=user$i-table-changes quay.io/openshiftdemos/python-kafka-consumer:latest
	oc expose -n user$i-eda svc/python-kafka-consumer
	oc expose -n user$i-eda svc/python-kafka-producer
	# hit the producer endpoint
	PRODUCER_ENDPOINT=$(oc get route -n user$i-eda python-kafka-producer -o jsonpath='{.spec.host}')
	curl http://$PRODUCER_ENDPOINT
	oc create -n user$i-eda -f /tmp/cockroach-kafka-eda/pipelines/tasks.yaml -f /tmp/cockroach-kafka-eda/pipelines/pipeline.yaml
	tkn pipeline start build-and-deploy-ms \
	-n user$i-eda \
	-w name=shared-workspace,volumeClaimTemplateFile=/tmp/cockroach-kafka-eda/pipelines/pipelinepvc.yaml \
	-p deployment-name-p=eda-producer-ms-ep \
	-p deployment-name-c=eda-consumer-ms-ep \
	-p git-url=https://$GITEA_ENDPOINT/user$i/cockroach-kafka-eda.git \
	-p IMAGE-P=image-registry.openshift-image-registry.svc:5000/user$i-eda/eda-ms-producer \
	-p IMAGE-C=image-registry.openshift-image-registry.svc:5000/user$i-eda/eda-ms-consumer \
	-p KAFKA_BROKER='crdb-cluster-kafka-bootstrap.crdb-kafka.svc.cluster.local:9092' \
	-p KAFKA_GROUP_ID=user$i-groupid \
	-p KAFKA_TOPIC=user$i-topic \
	-p KAFKA_CLIENT_ID=user$i-clientid \
	--use-param-defaults
done