#!/bin/bash

CLUSTER_NAME=${1:-localhost}
PASSWORD=${2:-cassandra}

CLIENT_PUBLIC_CERT=client.cert

ORGANISATION="OU=None, O=None, L=None, C=None"


KEY_STORE_PATH="./certs"
mkdir -p "$KEY_STORE_PATH"
KEY_STORE="$KEY_STORE_PATH/cassandra.keystore"
PKS_KEY_STORE="$KEY_STORE_PATH/cassandra.keystore.pks12"
TRUST_STORE="$KEY_STORE_PATH/cassandra.truststore"

CLUSTER_PUBLIC_CERT="$KEY_STORE_PATH/server.cert"

echo Create the cluster key for cluster communication.
keytool -genkey -keyalg RSA -alias "${CLUSTER_NAME}_cluster" -keystore "$KEY_STORE" -storepass "$PASSWORD" -keypass "$PASSWORD" \
-dname "CN=$CLUSTER_NAME, $ORGANISATION" \
-validity 36500

echo Create the public key for the cluster which is used to identify nodes.
keytool -export -alias "${CLUSTER_NAME}_cluster" -file "$CLUSTER_PUBLIC_CERT" -keystore "$KEY_STORE" \
-storepass "$PASSWORD" -keypass "$PASSWORD" -noprompt

echo Import the identity of the cluster public cluster key into the trust store so that nodes can identify each other.
keytool -import -v -trustcacerts -alias "${CLUSTER_NAME}_cluster" -file "$CLUSTER_PUBLIC_CERT" -keystore "$TRUST_STORE" \
-storepass "$PASSWORD" -keypass "$PASSWORD" -noprompt

echo Creeate a pks12 keystore file
keytool -importkeystore -srckeystore "$KEY_STORE" -destkeystore "$PKS_KEY_STORE" -deststoretype PKCS12 \
-srcstorepass "$PASSWORD" -deststorepass "$PASSWORD"

echo Create the client key.
keytool -genkey -keyalg RSA -alias "${CLUSTER_NAME}_client" -keystore "$KEY_STORE" -storepass "$PASSWORD" -keypass "$PASSWORD" \
-dname "CN=$CLUSTER_NAME, $ORGANISATION" \
-validity 36500

echo Create the public key for the client to identify itself.
keytool -export -alias "${CLUSTER_NAME}_client" -file "${KEY_STORE_PATH}/$CLIENT_PUBLIC_CERT" -keystore "$KEY_STORE" \
-storepass "$PASSWORD" -keypass "$PASSWORD" -noprompt

echo Import the identity of the client pub  key into the trust store so nodes can identify this client.
keytool -importcert -v -trustcacerts -alias "${CLUSTER_NAME}_client" -file "${KEY_STORE_PATH}/$CLIENT_PUBLIC_CERT" -keystore "$TRUST_STORE" \
-storepass "$PASSWORD" -keypass "$PASSWORD" -noprompt

echo create openssl server pub certificate
openssl pkcs12 -in "$PKS_KEY_STORE" -nokeys -out "${KEY_STORE_PATH}/client.cert.pem" -passin pass:${PASSWORD}
echo create openssl client cert and private key
openssl x509 -inform der -in "${KEY_STORE_PATH}/$CLIENT_PUBLIC_CERT" -outform pem -out "${KEY_STORE_PATH}/trusted.cert.pem"
openssl pkcs12 -in "$PKS_KEY_STORE" -nodes -nocerts -out "${KEY_STORE_PATH}/client.key.pem" -passin pass:${PASSWORD}
