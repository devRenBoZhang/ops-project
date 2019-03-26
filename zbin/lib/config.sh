#!/bin/bash

function getConfig() {
    if [[ $# -lt 1 ]]
    then
        echo "get config error. please input config name"
    fi
    configName=$1
    awk -v key=${configName} -F "=" '{con[$1]=$2}END{for(v in con){if(key==v){print con[v]}}}' ${BASE}/conf/config.properties
}
