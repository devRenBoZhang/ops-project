#!/bin/bash

pushd `dirname $0`/.. > /dev/null
BASE=`pwd`
popd > /dev/null
cd ${BASE}

function describe() {
    echo -e "checkConfig (选项) 项目名 \n清理项目分支，默认保存master分支，其他依次提供删除选项 \n\n【选项】 \n-d:删除选定的分支 \n-p参数:projects项目名,以“,”分隔 \n-r:同时删除远程分. \n-h:help帮助"
}


TEMP=`getopt -o "hf:p:" -n "checkConfig.sh" -- "$@" 2> /dev/null`
if [[ $? != 0 ]]; then
    echoError "param error";
    describe;
    exit 1;
fi
eval set -- "${TEMP}"
while true; do
    case "$1" in
        -h)
            describe;
            shift;
            exit 0 ;;
        -f)
            file_dir=$2
            shift 2
        ;;
        -p)
            project_dir=$2
            shift 2
        ;;
        --) shift; break ;;
        *)
            echoError "param error";
            describe
            exit 1 ;;
    esac
done
for arg do
    args=${args}","${arg}
done
argArray=( ${args//,/ } )
if [[ ${#argArray[@]} -gt 0 ]]; then
    proName=${argArray[0]}
fi

if [[ "XX" == "X${file_dir}X" || "XX" == "X${project_dir}X" ]]; then
    echo "file and project dir is necessary. please check."
    exit 2
fi



cd ${file_dir}

configKeys=`cat dubbo.properties | grep -vE "^#.*" | grep "=" | awk -F "=" '{dd=dd","$1;}END{print dd}'`
configKeyArray=( ${configKeys//,/ } )

cd ${project_dir}
resourcesFile=`find . -name "*.xml" | grep "resources"`
for key in ${configKeyArray[*]}
do
    keyExists=`echo ${resourcesFile} | grep "resources" | xargs grep ${key}`
    if [[ -z "${keyExists}" ]]; then
        echo "key:${key} has not config value in dubbo config filter"
        sed -i '/^.*'${key}'.*$/d' ${file_dir}/dubbo.properties
    fi
done