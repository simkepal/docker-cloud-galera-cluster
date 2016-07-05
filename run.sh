#!/bin/bash

while [ "${DOCKERCLOUD_SERVICE_API_URL}x" = "x" ]
do
    sleep 1;
done

echo $DOCKERCLOUD_SERVICE_API_URL

NODE_ADDR=$(echo ${DOCKERCLOUD_IP_ADDRESS} | awk -F\/ '{print $1}')
CLUSTER=""

#get containers links
T=$(curl -s -H "Authorization: $DOCKERCLOUD_AUTH" -H "Accept: application/json" $DOCKERCLOUD_SERVICE_API_URL | grep -o -P '(?<=containers).*' | cut -d "[" -f2 | cut -d "]" -f1)
links=$(echo $T | tr "," "\n")
for addr in $links
do
        A=$(echo "$addr" | sed -e 's/^"//'  -e 's/"$//')
        A="https://cloud.docker.com$A"
        T=$(curl -s -H "Authorization: $DOCKERCLOUD_AUTH" -H "Accept: application/json" $A | tr ',' '\n' | grep private_ip | awk -F\" '{print $4}' | awk -F\/ '{print $1}' | sort -u)
        #if [ $T != $NODE_ADDR ]; then
            CLUSTER="${CLUSTER}${T},"
        #fi
done


echo $CLUSTER
CLUSTER="${CLUSTER%?}"
echo $CLUSTER

if [ "x${CLUSTER}" = "x" ]; then
    echo "I'm alone ${NODE_ADDR} Bootstrap Cluster (Throw away container if this is not the first container)"
    CLUSTER="gcomm://"
else
    echo "I'm not alone! My buddies: ${CLUSTER} and me ${NODE_ADDR}"
    CLUSTER="gcomm://${CLUSTER}"
fi

echo $CLUSTER


INNOBDB_BUFFER_POOL_SIZE=$((`cat /proc/meminfo | grep MemTotal | cut -d ' ' -f 9` / 2000))M
#
echo "wsrep_cluster_address=$CLUSTER" >> /etc/mysql/conf.d/cluster.cnf
echo "wsrep_node_address=$NODE_ADDR" >> /etc/mysql/conf.d/cluster.cnf
echo "wsrep_node_incoming_address=$NODE_ADDR" >> /etc/mysql/conf.d/cluster.cnf
echo "wsrep_node_name=$HOSTNAME" >> /etc/mysql/conf.d/cluster.cnf

echo $INNOBDB_BUFFER_POOL_SIZE

echo /docker-entrypoint.sh --innodb_buffer-pool-size=$INNOBDB_BUFFER_POOL_SIZE --wsrep_node_address="${NODE_ADDR}" --wsrep_node_incoming_address="${NODE_ADDR}" --wsrep_cluster_address="${CLUSTER}" --wsrep_node_name=${HOSTNAME} ${EXTRA_OPTIONS}
#/usr/bin/mysqld_safe --wsrep_node_address="${NODE_ADDR}" --wsrep_node_incoming_address="${NODE_ADDR}" --wsrep_cluster_address="${CLUSTER}" --wsrep_node_name=${HOSTNAME} ${EXTRA_OPTIONS}

#cat /docker-entrypoint.sh

if [ $HOSTNAME = "mariadb-1" ]; then
    /docker-entrypoint.sh --wsrep-new-cluster --innodb_buffer-pool-size=$INNOBDB_BUFFER_POOL_SIZE
else
    /docker-entrypoint.sh --innodb_buffer-pool-size=$INNOBDB_BUFFER_POOL_SIZE
fi
