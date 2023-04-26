#!/bin/bash
COCKROACH_DB_SECRET=`oc get servicebinding -o json | jq -cr .items[0].status.secret`
COCKROACH_DB_HOST=`oc get secret $COCKROACH_DB_SECRET -o json | jq -cr .data.host | base64 -d`
COCKROACH_DB_USER=`oc get secret $COCKROACH_DB_SECRET -o json | jq -cr .data.username | base64 -d`
COCKROACH_DB=` oc get secret $COCKROACH_DB_SECRET -o json | jq -cr .data.options | base64 -d | cut -d= -f2`
COCKROACH_DB_PASSWORD=`oc get secret $COCKROACH_DB_SECRET -o json | jq -cr .data.password | base64 -d`

echo "Use this password: $COCKROACH_DB_PASSWORD"
cockroach sql --url "postgresql://$COCKROACH_DB_USER@$COCKROACH_DB_HOST:26257/$COCKROACH_DB.defaultdb?sslmode=verify-full"