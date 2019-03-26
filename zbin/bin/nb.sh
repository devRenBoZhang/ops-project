###########################################
####nBranch name [baseBranch] [projects]
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
    echo -e "nb (选项) 分支名 \n\n【选项】\n-l:local本地新增分支，不推送 \n-b参数:baseBranchName新分支的基准分支名 \n-p参数:projects项目名,以“,”分隔 \n-h:help帮助"
}


function checkLocal() {
    echoProcess "new branch>>checkLocal staring"
    rel_local=$1
    bb=`git branch | grep -w ${rel_local} | sed s/[[:space:]]//g | sed s/*//g`
    if [[ -n "$bb" && ${#bb} == ${#rel_local} ]]
    then
        echoWarn "already has this branch:${rel_local},will checkout branch"
        git checkout "$rel_local"
        if [[ $? -ne 0 ]]
        then
            echoError "checkout local branch is error,please check "
            exit 2
        fi
        synRemote $1
        echoSuccess "checkLocal success. cur_branch is in $rel_local "
    fi

}

function checkRemote() {
    echoProcess "new branch>>checkRemote staring"
    rel_remote=$1
    re_rel="remotes/origin/$rel_remote"
    bb_remote=`git branch -a | grep -w ${re_rel} | sed s/[[:space:]]//g`
    if [[ -n "$bb_remote" && ${#bb_remote} == ${#re_rel} ]]
    then
        echoWarn "remote has this branch:${rel_local},will checkout branch"
        git checkout -b "$rel_remote" "origin/$rel_remote"
        if [[ $? -ne 0 ]]
        then
            echoError "checkout remote branch is error,please check "
            exit 2
        fi
        synRemote ${rel_remote}
        echoSuccess "checkRemote success. cur_branch is in $rel_local "
    else
        echoProcess "new branch>>newBranch staring on ${baseBra}"
        checkout_branch ${baseBra}
        git checkout -b "${rel_remote}"
    fi
}

function createBranch() {
    if [[ $# -lt 1 ]]; then
        echoError "new branch name is necessary"
        exit 2
    fi
    checkLocal $*

    cur_bb_cre=`git symbolic-ref -q HEAD | cut -b 12-`
    if [[ "$cur_bb_cre" == "$1" ]]
    then
        return 0
    fi

    checkRemote $*
}

function dbArgsDesc() {
    dbArgsDesc="nb works args summary ######\n###### baseBranch:${baseBra}"
    if [[ "XX" != "X${ass_nb_workStr}X" ]]; then
        dbArgsDesc="${dbArgsDesc}\n###### works:${ass_nb_workStr}"
    else
        dbArgsDesc="${dbArgsDesc}\n###### works:${nb_pro_str}"
    fi
    if [[ "XX" != "X${cmd}X" ]]; then
        dbArgsDesc="${dbArgsDesc}\n###### option:${cmd}"
    fi
    echoBase "${dbArgsDesc}"
}

########################################################################################################################
#################### start shell

baseBra="master"
cmd="push"

TEMP=`getopt -o "hb:lp:" -n "nb.sh" -- "$@" 2> /dev/null`
if [[ $? != 0 ]]; then
    echoError "param input error";
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
        -b)
            baseBra=$2;
            shift 2 ;;
        -l)
            cmd="new";
            shift;;
        -p)
            ass_nb_workStr=`getWorks $2`
            if [[ $? != 0 ]]; then
                exit 2;
            fi
            if [[ "XX" == "X${ass_nb_workStr}X" ]]; then
                echoError "assign project error. no this config, please check"
                exit 2
            fi
            shift 2 ;;
        --) shift;
        break ;;
        *)
            echoError "param parse error";
            describe
            exit 1 ;;
    esac
done
for arg do
    args=${args}","${arg}
done
argArray=( ${args//,/ } )
branchName=${argArray[0]}

if [[ "XX" == "X${branchName}X" ]]; then
    echoError "new branch name is necessary"
    describe
    exit 2
fi

nb_gitReStr=`getConfig "gitRep_dirs"`
if [[ "XX" == "X${nb_gitReStr}X" ]]; then
    echoWarn "no config execute dir list. please check"
    exit 2
fi
nb_gitReps=( ${nb_gitReStr//,/ } )
for gitRep in ${nb_gitReps[*]}
do
    cd ${gitRep}
    nb_pro_str=`getDirProjectNames`
    if [[ "XX" == "X${nb_pro_str}X" ]]; then
        echoWarn "${gitRep} no project found. please check"
        continue
    fi
    nb_pro_work=( ${nb_pro_str//,/ } )
    dbArgsDesc
    for work in ${nb_pro_work[*]}
    do
        work="${work%%-project*}-project"
        isContain=`isContainWork ${work} ${ass_nb_workStr}`
        if [[ "XyX" != "X${isContain}X" ]]; then
            continue
        fi
        echoLocation "$work is staring new branch"
        cd "${gitRep}/$work"
        createBranch ${branchName}

        if [[ "$cmd" == "push" ]]
        then
            pushBranch ${branchName} ${work}
        fi
    done
done
