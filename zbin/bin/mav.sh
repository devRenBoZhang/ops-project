#!/bin/bash

pushd `dirname $0`/.. > /dev/null
BASE=`pwd`
popd > /dev/null
cd ${BASE}

. ${BASE}/lib/config.sh
. ${BASE}/lib/fun_base.sh
. ${BASE}/lib/git-help/fun_git.sh
. ${BASE}/lib/mvn-help/fun_help.sh

pomDir=`getConfig "pomDir"`

function describe() {
    echo -e "nb  (选项) (项目名称<多个直接以" "分隔>) (mvn phase<clean install deploy...>) \n\n【选项】\n-a参数:mvn am option \n-b参数:mvn branch, if not exists then mater \n-D参数:mvn args \n-f:flush pom modules by type\n-h:help帮助\n-P参数:mvn p options \n-r参数:mvn ref options\n-t参数:mvn type in install,deploy,pl\n"
}

########################################################################################################################
#################### start shell

mvnActiveP="runtime"
mvnD="skipTests"
mvnPl="-pl"

TEMP=`getopt -o "a:b:D:fhP:r:t:" -n "mav.sh" -- "$@" 2> /dev/null`
if [[ $? != 0 ]]; then
    echoError "param error";
    describe;
    exit 1;
fi
eval set -- "${TEMP}"
while true; do
    case "$1" in
        -a)
            am=$2;
            shift 2 ;;
        -b)
            branch=$2;
            shift 2 ;;
        -D)
            mvnD=$2;
            shift 2 ;;
        -f)
            flush="y";
            shift ;;
        -h)
            describe;
            shift;
            exit 0 ;;
        -P)
            mvnActiveP=$2;
            shift 2 ;;
        -r)
            rf=$2;
            shift 2 ;;
        -t)
            type=$2;
            shift 2 ;;
        --) shift; break ;;
        *)
            echoError "param parse error";
            describe
            exit 1 ;;
    esac
done
for arg do
    case ${arg} in
        "validate" | "compile" | "test" | "package" | "verify" | "install" | "deploy" | "clean" | "site")
            globals="${globals} ${arg}"
        ;;
        *)
            projectName=${projectName}","${arg}
        ;;
    esac
done

if [[ "XX" != "X${branch}X" ]]; then
    syn.sh ${branch}
fi

if [[ "XX" == "X${type}X" && "XX" == "X${projectName}X" ]]; then
    echoError "mvn type is required, please check"
    exit 2
fi
if [[ "XX" == "X${type}X" && "XX" != "X${projectName}X" ]]; then
    type=pl
fi

echoBase "mvn project. project: ${projectName}, type:${type}"
case "${type}" in
    "pl" | "install" | "deploy")
    ;;
    *)
        echoError "not this type, please check."
        describe
        exit 2
    ;;
esac

if [[ "XyX" == "X${flush}X" ]]; then
    echoProcess "reloadModules starting"
    reloadModules "pl"
    reloadModules "mav"
    if [[ "XplX" != "X${type}X" && "XmavX" != "X${type}X" ]]; then
        reloadModules ${type}
    fi
fi

cd ${pomDir}/pl
if [[ "XX" != "X${rf}X" ]]; then
    mvnRf=`grep "${rf}" pom.xml | cut -d ">" -f 2 | cut -d "<" -f 1`
    mvnRf="-rf ${mvnRf}"
fi

cd ${pomDir}/${type}
case "${type}" in
    "install")
        mvnPl=""
        if [[ "X${globals}X" == "XX" ]]; then
            globals="clean install"
        fi
    ;;
    "deploy")
        mvnPl=""
        if [[ "X${globals}X" == "XX" ]]; then
            globals="clean deploy"
        fi
    ;;
    "pl")
        if [[ "XX" == "X${projectName}X" ]]; then
            echoError "projectName is required. please check"
            describe
            exit 2
        fi
        proArrays=( ${projectName//,/ } )
        for VAR in ${proArrays[*]}; do
            mvProPl="${mvProPl},"`grep "${VAR}" pom.xml | cut -d ">" -f 2 | cut -d "<" -f 1`
        done
        mvProPl=${mvProPl#,}
        if [[ "X${globals}X" == "XX" ]]; then
            globals="clean install"
        fi
        cd ${pomDir}/mav
    ;;
    *)
        echoError "no this type. please check"
        shift 2 ;;
esac


echoProcess "mvn ${globals} ${mvnPl} ${mvProPl} -am ${mvnRf} -P${mvnActiveP} -D${mvnD}"
mvn ${globals} ${mvnPl} ${mvProPl} -am ${mvnRf} -P${mvnActiveP} -D${mvnD}