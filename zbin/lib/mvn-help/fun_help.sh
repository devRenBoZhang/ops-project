#!/bin/bash

excludeProStr=`getConfig "excludePro"`
excludePro=( ${excludeProStr//,/ } )

function reloadPomXml() {
    cd ${pomDir}
    mkdir ${reloadType} 2> /dev/null
    cd ${reloadType}
    touch pom.xml 2> /dev/null
    > pom.xml
    cat ${pomDir}/pom-temp.xml >> pom.xml
}

# ----------------------
# 获取选定的mvn模块
# 第一个入参：过滤管道参数 eg:grep -e "XXX" | grep -v "AAA"
function pickMvnModule() {
    pickCmd=$1
    mvnModulesCmd="mvn clean -am | grep '.*INFO.*SUCCESS.*\[.*\].*' | awk '{print "'$2'" }'"
    if [[ "XX" != "X${pickCmd}X" ]]; then
        mvnModulesCmd="${mvnModulesCmd} | ${pickCmd#\|}"
    fi
    cd ${pomDir}/mav
    echoBase "###### reloadModules summary\n###### executeDir:${pomDir}/mav \n###### moduleType:${reloadType}\n###### cmd: ${mvnModulesCmd}"
    modules=( `eval ${mvnModulesCmd}` )
    cd ${pomDir}/pl
    for VAR in ${modules[*]}; do
        modulePath=`egrep ".*${VAR}</module>$" pom.xml`
        if [[ "XX" != "X${modulePath}X" ]]; then
            echo ${modulePath} >> ${pomDir}/${reloadType}/pom.xml
        fi
    done
    echo "</modules></project>" >> ${pomDir}/${reloadType}/pom.xml
}

function parsePomInfo() {
    gitRep=$1
    parse_pro_str=$2
    if [[ "XX" == "X${parse_pro_str}X" ]]; then
        echoWarn "${gitRep} no project found to mav. please check"
        return 1
    fi
    cd ${gitRep}
    pwdDir=`pwd`
    mvnDir="${pomDir}/${reloadType}"
    pomRelativePath=`getRelativeDir ${mvnDir} ${pwdDir}`
    pomRelativePath="${pomRelativePath//\//\\/}\\/"
    case "${reloadType}" in
        "mav")
            echoBase "###### reloadModules summary\n###### executeDir:${pwdDir} \n###### moduleType:${reloadType}\n###### cmd: ${relatePathCmd}"
            mav_pro_work=( ${parse_pro_str//,/ } )
            for work in ${mav_pro_work[*]}
            do
                executePathCmd='find ./'${work}'/ -maxdepth 1 -name pom.xml | '"${relatePathCmd}| sed  \"s/\.\/\(.*\)\/pom\.xml/<module>${pomRelativePath}\1<\/module>/\""
                echoProcess "###### ${work} reloadModules stating...."
                eval ${executePathCmd} >> ${pomDir}/${reloadType}/pom.xml
            done
        ;;
        "pl")
            echoBase "###### reloadModules summary\n###### executeDir:${pwdDir} \n###### moduleType:${reloadType}\n###### cmd: ${relatePathCmd}"
            pl_pro_work=( ${parse_pro_str//,/ } )
            for work in ${pl_pro_work[*]}
            do
                executePathCmd='find ./'${work}'/ -name pom.xml | '"${relatePathCmd}| sed  \"s/\.\/\(.*\)\/pom\.xml/<module>${pomRelativePath}\1<\/module>/\""
                echoProcess "###### ${work} reloadModules stating...."
                eval ${executePathCmd} >> ${pomDir}/${reloadType}/pom.xml
            done
        ;;
    esac
}

function reloadModules() {
    if [[ $# -gt 0 ]]; then
        reloadType=$1;
    fi
    if [[ "XX" == "X${reloadType}X" ]]; then
        echoError "reloadModules type is required. please check"
        exit 2;
    fi
    reloadPomXml
    case "${reloadType}" in
        "install")
            relatePathCmd='egrep -e ".*libs-project$" -e ".*facade-project$" -e ".*facade$"  -e ".*lib-project$"'
            installProStr=`getConfig "installPro"`
            installProArray=( ${installProStr//,/ } )
            for pro in ${installProArray[*]}
            do
                relatePathCmd=${relatePathCmd}' -e ".*'${pro}'$"'
            done
            installExcludeProStr=`getConfig "installExcludePro"`
            installExcludeProArray=( ${installExcludeProStr//,/ } )
            for exIns in ${installExcludeProArray[*]}
            do
                relatePathCmd=${relatePathCmd}'| grep -vE ".*'${exIns}'$" '
            done
            pickMvnModule "${relatePathCmd}"
            return 1
        ;;
        "deploy")
        #### deploy默认执行facade和lib项目，可用deployPro或deployExcludePro指定特定的项目名，和项目路径无关
            relatePathCmd='egrep -e ".*libs-project$" -e ".*facade-project$" -e ".*facade$"  -e ".*lib-project$"'
            deployProStr=`getConfig "deployPro"`
            deployProArray=( ${deployProStr//,/ } )
            for dp in ${deployProArray[*]}
            do
                relatePathCmd=${relatePathCmd}' -e ".*'${dp}'$"'
            done

            deployExcludeProStr=`getConfig "deployExcludePro"`
            deployExcludeProArray=( ${deployExcludeProStr//,/ } )
            for dep in ${deployExcludeProArray[*]}
            do
                relatePathCmd=${relatePathCmd}'| grep -vE ".*'${dep}'$" '
            done
            deployContainStr=`getConfig "deployContainStr"`
            if [[ "XX" != "X${deployContainStr}X" ]]; then
                relatePathCmd=${relatePathCmd}'| egrep '
            fi
            deployContainArray=( ${deployContainStr//,/ } )
            for limitStr in ${deployContainArray[*]}
            do
                relatePathCmd=${relatePathCmd}' -e ".*'${limitStr}'.*" '
            done
            pickMvnModule "${relatePathCmd}"
            return 1
        ;;
        "pl" | "mav")
            relatePathCmd='grep -v "target" '
            for ePro in ${excludePro[*]}
            do
                relatePathCmd=${relatePathCmd}'| grep -vE "^.*'${ePro}'.*" '
            done
            reload_gitReStr=`getConfig "gitRep_dirs"`
            if [[ "XX" == "X${reload_gitReStr}X" ]]; then
                echoWarn "no config execute dir list. please check"
                exit 2
            fi
            reload_gitReps=( ${reload_gitReStr//,/ } )
            for gitRep in ${reload_gitReps[*]}
            do
                cd ${gitRep}
                parsePomInfo ${gitRep} `getDirProjectNames`
            done
            #### 指定的特殊项目，直接到项目目录
            reload_gitProStr=`getConfig "gitRep_pros"`
            if [[ "XX" != "X${reload_gitProStr}X" ]]; then
                reload_gitRros=( ${reload_gitProStr//,/ } )
                for gitPro in ${reload_gitRros[*]}
                do
                    parsePomInfo ${gitPro%/*} ${gitPro##*/}
                done
            fi
            echo "</modules></project>" >> ${pomDir}/${reloadType}/pom.xml
        ;;
        *)
            echoError "there not this mvn type. please check."
            exit 2
        ;;
    esac
}






