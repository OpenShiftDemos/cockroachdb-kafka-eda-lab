#!/bin/bash
COCKROACH_DB_SECRET=`oc get servicebinding -o json | jq -cr .items[0].status.secret`
COCKROACH_DB_HOST=`oc get secret $COCKROACH_DB_SECRET -o json | jq -cr .data.host | base64 -d`
COCKROACH_DB_USER=`oc get secret $COCKROACH_DB_SECRET -o json | jq -cr .data.username | base64 -d`