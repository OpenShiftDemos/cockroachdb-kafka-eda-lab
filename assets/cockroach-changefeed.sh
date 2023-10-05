#!/bin/bash
COCKROACH_DB_SECRET=`oc get servicebinding -o json | jq -cr .items[0].status.secret`
COCKROACH_DB_HOST=`oc get secret $COCKROACH_DB_SECRET -o json | jq -cr .data.host | base64 -d`
COCKROACH_DB_USER=`oc get secret $COCKROACH_DB_SECRET -o json | jq -cr .data.username | base64 -d`
COCKROACH_DB=` oc get secret $COCKROACH_DB_SECRET -o json | jq -cr .data.options | base64 -d | cut -d= -f2`
COCKROACH_DB_PASSWORD=`oc get secret $COCKROACH_DB_SECRET -o json | jq -cr .data.password | base64 -d`

KAFKA_ROUTE=`oc get route crdb-cluster-kafka-external-bootstrap -n crdb-kafka -o json | jq -cr .spec.host`
oc get kafka crdb-cluster -n crdb-kafka -o json | jq -cr .status.listeners[1].certificates[0] | sed '/^$/d' > /tmp/kafka-cert.txt
KAFKA_CERT_BASE64=`cat /tmp/kafka-cert.txt | base64 -w0 -`
USERNAME=`echo $WORKSHOP_VARS | jq -cr .user`

echo "Use this password: $COCKROACH_DB_PASSWORD"

cockroach sql --url "postgresql://$COCKROACH_DB_USER@$COCKROACH_DB_HOST:26257/$COCKROACH_DB.defaultdb?sslmode=verify-full" \
-e "CREATE CHANGEFEED FOR TABLE $USERNAME.fruitoutbox INTO 'kafka://$KAFKA_ROUTE:443?topic_name=$USERNAME-table-changes&tls_enabled=true&ca_cert=$KAFKA_CERT_BASE64';"
