#!/bin/bash

function getConfig() {
    if [[ $# -lt 1 ]]
    then
        echo "get config error. please input config name"
    fi
    configName=$1
    awk -v key=${configName} -F "=" '{con[$1]=$2}END{for(v in con){if(key==v){print con[v]}}}' ${BASE}/conf/config.properties
}

function getProConfigs() {
    if [[ $# -lt 1 ]]
    then
        echo "get project configs error. please input project name"
    fi
    pro_name=$1
    pro_configs_v=()
    proConfigs_pro_name=$1
    pro_configs_v=$(cat ${BASE}/conf/work.properties | awk -v proConfigs_pro_name=${pro_name} -F '\\]|\\[' '{if($2==proConfigs_pro_name) {startNum=NR;array["active_name"]=$2;}else if($2!="" && $2!=proConfigs_pro_name){startNum=20000;};if(NR>startNum){bv=$1;split(bv,vs,":");bk=vs[1];bva=vs[2] ;array[bk]=bva}}'END'{ for(item in array) {print item":"array[item]}; }')

    for var in ${pro_configs_v[*]}; do
        echo "${var} "
    done
}