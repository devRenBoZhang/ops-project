###########################################
####dBranch name [del|save] [projects]
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
    echo -e "db (选项) (分支名) \n清理项目分支，默认保存master分支，其他依次提供删除选项 \n\n【选项】 \n-d:删除选定的分支 \n-p参数:projects项目名,以“,”分隔 \n-r:同时删除远程分. \n-h:help帮助"
}

function delBranch() {
    drel=$1
    d_work=$2
    isContain=`git branch | grep -wq "$drel" && echo 1 || echo 0`
    if [[ ${isContain} -eq 0 ]]
    then
        echoWarn "${d_work} local not this branch ${drel},already ignore"
        return 1
    fi
    echoInput "${d_work} ${drel} will delete. whether to continue. (y or n)"
    read isDel
    if [[ "y" != "$isDel" ]]
    then
        return 1
    fi
    cur_bb=`git symbolic-ref -q HEAD | cut -b 12-`
    if [[ "$cur_bb" == "$drel" ]]
    then
        echoWarn "You want delete current branch. checkout master now. work:${d_work},branch:${drel}"
        switch_branch "$saveBr"
    fi
    dbLog=`git log origin/${drel}..${drel}`
    if [[ -n "${dbLog}" ]]
    then
        echo "=========================================================================="
        git log --stat origin/${drel}..${drel}
        echoInput "${d_work} $drel has commits which not push. whether to continue. (y or n)"
        read dbLogcmd
        if [[ "y" == "${dbLogcmd}" ]]
        then
            echo ""
        else
            return 1
        fi
    fi
    git branch -d "$drel"

    if [[ $? -ne 0 ]]; then
        echoError "Delete local branch error. work:${d_work},branch:${drel}"
        echoInput "Please choose any of the following options\nf:force; i:ignore; else exit"
        read isForce
        if [[ "XfX" == "X${isForce}X" ]]
        then
            git branch -D "$drel"
        elif [[ "i" == "$isForce" ]]
        then
            return 1
        else
            exit 2
        fi
    fi
    if [[ "XyX" == "X${delRemote}X" ]]; then
        echoInput "delete remote. ${d_work} ${drel}. whether to continue. (y or n)"
        read isDel
        if [[ "XyX" != "X${isDel}X" ]]; then
            return 1
        fi
        git push -u --progress origin :${drel}
        if [[ $? -ne 0 ]]; then
            echoInput "del branch error. work:${d_work},branch:${drel}, whether to continue. (y or n)"
            read dbRemoteC
            if [[ "XyX" == "X{dbRemoteC}X" ]]; then
                return 1
            else
                exit 2
            fi
        else
            echoSuccess "delete remote origin branch:${drel} success"
        fi
    fi
    echoSuccess "${d_work} ${drel} del success"
}

function saveBranch() {
    srel=$1
    cur_bb=`git symbolic-ref -q HEAD | cut -b 12-`
    if [[ "$cur_bb" != "$srel" ]]
    then
        switch_branch ${srel}
    fi
    delBranchs=`git branch | grep -vw "$srel" | sed s/[[:space:]]//g`
    for br in ${delBranchs}
    do
        delBranch ${br} $2
    done
}

function dbArgsDesc() {
    dbArgsDesc="db works args summary ######\n###### clearBranch:${clearBra}"
    if [[ "XX" != "X${ass_db_workStr}X" ]]; then
        dbArgsDesc="${dbArgsDesc}\n###### works:${ass_db_workStr}"
    else
        dbArgsDesc="${dbArgsDesc}\n###### works:${db_pro_str}"
    fi
    if [[ "XX" != "X${cmd}X" ]]; then
        dbArgsDesc="${dbArgsDesc}\n###### option:${cmd}"
    fi
    echoBase "${dbArgsDesc}"
}

########################################################################################################################
#################### start shell

cmd="save"
saveBr="master"

TEMP=`getopt -o "hdp:r" -n "db.sh" -- "$@" 2> /dev/null`
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
        -d)
            cmd="del"
            shift ;;
        -p)
            ass_db_workStr=`getWorks $2`
            if [[ $? != 0 ]]; then
                exit 2;
            fi
            if [[ "XX" == "X${ass_db_workStr}X" ]]; then
                echoError "assign project error. no this config, please check"
                exit 2
            fi
            shift 2 ;;
        -r)
            delRemote="y"
            shift ;;
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
if [[ ${#argArray[@]} -gt 0 ]]; then
    clearBra=${argArray[0]}
fi


if [[ "XX" == "X${clearBra}X" ]]; then
    clearBra="master"
fi

if [[ "XmasterX" == "X${clearBra}X" && "XdelX" == "X${cmd}X" ]]; then
    echoError "can not delete master. please check options."
    exit 2
fi


db_gitReStr=`getConfig "gitRep_dirs"`
if [[ "XX" == "X${db_gitReStr}X" ]]; then
    echoWarn "no config execute dir list. please check"
    exit 2
fi
db_gitReps=( ${db_gitReStr//,/ } )
for gitRep in ${db_gitReps[*]}
do
    cd ${gitRep}
    db_pro_str=`getDirProjectNames`
    if [[ "XX" == "X${db_pro_str}X" ]]; then
        echoWarn "${gitRep} no project found. please check"
        continue
    fi

    dbArgsDesc

    db_pro_work=( ${db_pro_str//,/ } )
    for work in ${db_pro_work[*]}
    do
        work="${work%%-project*}-project"
        isContain=`isContainWork ${work} ${ass_db_workStr}`
        if [[ "XyX" != "X${isContain}X" ]]; then
            continue
        fi

        cd "${gitRep}/$work"
        echoLocation "${work} clear branch starting"
        if [[ "$cmd" == "del" ]]
        then
            delBranch ${clearBra} ${work}
        fi
        if [[ "$cmd" == "save" ]]
        then
            saveBranch ${clearBra} ${work}
        fi
    done
done
