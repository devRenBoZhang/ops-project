#!/bin/bash

pidNames="java"
if [[ $# -gt 0 ]]
then
    pidNames=${1//,/\\|}
fi
cmd_ps="ps -ef | grep $pidNames | grep -v grep | grep -v $0 "
eval ${cmd_ps}
pidNum=`eval ${cmd_ps} | cut -c 9-15 | wc -l`
if [[ ${pidNum} -gt 0 ]]
then
    echo "****************************find these pids please check these,they kill be kill after input root passWork*********************"
    su -c " $cmd_ps | cut -c 9-15 | xargs kill -9 " root
    echo "**********************************************kill is success,the following pids was killed************************************ "
    eval ${cmd_ps} | cut -c 9-15
else
    echo "**********************************************not find pid to kill*********************************** "
fi
