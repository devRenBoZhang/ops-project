###########################################
####merge mergeBranchNames [baseBranchName] [projects] 
####
####
###########################################
#!/bin/bash

pushd `dirname $0`/.. > /dev/null
BASE=`pwd`
popd > /dev/null
cd ${BASE}


. ${BASE}/lib/config.sh
. ${BASE}/lib/fun_base.sh
. ${BASE}/lib/git-help/fun_git.sh

function describe() {
    echo -e "mg (选项) 合并分支(多个分支冒号分隔) (基准分支) \n\n【选项】 \n-p参数:projects项目名,以“,”分隔 \n-h:help帮助"
}

function dbArgsDesc() {
    dbArgsDesc="merge works args summary ######\n###### merge ${mergeBranchs} to ${baseBranch}"
    if [[ "XX" != "X${ass_mg_workStr}X" ]]; then
        dbArgsDesc="${dbArgsDesc}\n###### works:${ass_mg_workStr}"
    else
        dbArgsDesc="${dbArgsDesc}\n###### works:${mg_pro_str}"
    fi
    echoBase "${dbArgsDesc}"
}

########################################################################################################################
#################### start shell

baseBra="master"
cmd="push"

TEMP=`getopt -o "hp:" -n "mg.sh" -- "$@" 2> /dev/null`
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
        -p)
            ass_mg_workStr=`getWorks $2`
            if [[ $? != 0 ]]; then
                exit 2;
            fi
            if [[ "XX" == "X${ass_mg_workStr}X" ]]; then
                echoError "assign project error. no this config, please check"
                exit 2
            fi
            shift 2 ;;
        --) shift;
        break ;;
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
mergeBranchs=${argArray[0]}
baseBranch=${argArray[1]}

if [[ "XX" == "X${mergeBranchs}X" ]]; then
    echoError "mergeBranchs is necessary"
    describe
    exit 2
fi
mergeBranchs=${mergeBranchs//:/,}
#if [[ "XX" == "X${baseBranch}X" ]]; then
#    echoError "baseBranch is necessary"
#    describe
#    exit 2
#fi

mg_gitReStr=`getConfig "gitRep_dirs"`
if [[ "XX" == "X${mg_gitReStr}X" ]]; then
    echoWarn "no config execute dir list. please check"
    exit 2
fi
mg_gitReps=( ${mg_gitReStr//,/ } )
for gitRep in ${mg_gitReps[*]}
do
    cd ${gitRep}
    mg_pro_str=`getDirProjectNames`
    if [[ "XX" == "X${mg_pro_str}X" ]]; then
        echoWarn "${gitRep} no project found. please check"
        continue
    fi
    mg_pro_work=( ${mg_pro_str//,/ } )
    if [[ "XX" != "X${ass_mg_workStr}X" ]]; then
        mg_pro_str=""
        for work in ${mg_pro_work[*]}
        do
            work="${work%%-project*}-project"
            isContain=`isContainWork ${work} ${ass_mg_workStr}`
            if [[ "XyX" == "X${isContain}X" ]]; then
                mg_pro_str="${mg_pro_str},${work}"
            fi
        done
    fi
    dbArgsDesc
    mg_pro_work=( ${mg_pro_str//,/ } )
    #搜集基准分支，如果没有指定基础分支的则使用当前分支
    for work in ${mg_pro_work[*]}
    do
        work="${work%%-project*}-project"
        isContain=`isContainWork ${work} ${ass_mg_workStr}`
        if [[ "XyX" != "X${isContain}X" ]]; then
            continue
        fi

        if [[ -n "${baseBranch}" ]]; then
            branch_wk="${baseBranch}"
        else
            cd "${gitRep}/$work"
            branch_wk=`git symbolic-ref -q HEAD | cut -b 12-`
        fi
        branch_wk_arr="${branch_wk_arr};${work}:${branch_wk}"
    done

    wortStr=${mg_pro_work[*]}
    # 更新合并分支
    mergeBranchArray=( ${mergeBranchs//,/ } )
    for mergeBranch in ${mergeBranchArray[*]}
    do
        echoProcess "mergeBranch syn starting. branch:${mergeBranch}"
        syn.sh ${mergeBranch} -q -p${wortStr// /,}
        if [[ $? -ne 0 ]]; then
            echoError "mergeBranch syn error. branch:${mergeBranch}"
            exit 2
        fi
    done

    # 更新基准分支
    echoProcess "baseBranch syn starting. "
    for work in ${mg_pro_work[*]}
    do
        work="${work%%-project*}-project"
        branch_wk=`echo "${branch_wk_arr}" | awk -F "${work}:" '{print $2}' | cut -f1 -d ";"`
        syn.sh ${branch_wk} -q -p${work}
        if [[ $? -ne 0 ]]; then
            echoError "baseBranch syn is error,please check."
            exit 2
        fi
    done

    for mergeBranch in ${mergeBranchArray[*]}
    do
        for work in ${mg_pro_work[*]}
        do
            work="${work%%-project*}-project"
            cd "${gitRep}/$work"
            baseBb_work=`echo "${branch_wk_arr}" | awk -F "${work}:" '{print $2}' | cut -f1 -d ";"`
            if [[ "master" == "${baseBb_work}" ]]
            then
                echoProcess "merge master to ${work}:${baseBb_work} is running"
                mergeBb ${mergeBranch} ${baseBb_work} ${work}
            fi
            mergeBb ${baseBb_work} ${mergeBranch} ${work}
        done
    done

    echoSuccess "${mergeBranchs} merge to ${baseBranch} success"
    echoInput "You must confirm all works is merge right. following options\n p:push,e:exit"
    read mergeChoose
    if [[ "p" == "${mergeChoose}" ]]; then
        echo ""
    else
        exit 2
    fi

    for work in ${mg_pro_work[*]}
    do
        work="${work%%-project*}-project"
        baseBb_work=`echo "${branch_wk_arr}" | awk -F "${work}:" '{print $2}' | cut -f1 -d ";"`
        cd "${gitRep}/$work"
        pushBranch ${baseBb_work} ${work}
    done
done