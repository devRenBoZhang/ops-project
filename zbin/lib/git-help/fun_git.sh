#!/bin/bash

function synRemote() {
    curDirName=`getCurDirName`
    cur_bb_syn=`git symbolic-ref -q HEAD | cut -b 12-`
    if [[ "XX" == "X${cur_bb_syn}X" ]]; then
        git fetch
        return 0
    fi
    isUpStream=`git branch -vv | grep ${cur_bb_syn} | grep -q "\[" && echo 1 || echo 0`
    if [[ ${isUpStream} -eq 0 ]]
    then
        git fetch
        if [[ $? -ne 0 ]]
        then
            echoError "fetch is error, work:${curDirName}, branch:${cur_bb_syn}. please check."
            exit 2
        fi
    else
        git pull
        if [[ $? -ne 0 ]]
        then
            echoError "pull is error, work:${curDirName}, branch:${cur_bb_syn}. please check."
            exit 2
        fi
    fi
}

function checkout_branch() {
    cur_bb_check=`git symbolic-ref -q HEAD | cut -b 12-`
    if [[ "$cur_bb_check" != "$1" ]]
    then
        switch_branch $1
    else
        echoProcess "already in $1. just syn remote"
        synRemote $1
    fi
}

function switch_branch() {
    curDirName=`getCurDirName`
    rel_switch=$1
    bb_switch=`git branch | grep -w ${rel_switch} | sed s/[[:space:]]//g`
    if [[ -n "$bb_switch" ]] && [[ ${#bb_switch} == ${#rel_switch} ]]
    then
        echoProcess "already checkout $1. just syn remote"
        git checkout "$rel_switch"
        if [[ $? -ne 0 ]]
        then
            echoError "checkout local branch error. work:${curDirName},branch:${rel_switch}"
            exit 2
        fi
        synRemote ${rel_switch}
    else
        fetch_branch ${rel_switch}
    fi
}

function fetch_branch() {
    curDirName=`getCurDirName`
    synRemote $1
    rel_new=$1
    re_rel="remotes/origin/$1"
    bb_new=`git branch -a | grep -w ${re_rel} | sed s/[[:space:]]//g`
    if [[ -n "$bb_new" ]] && [[ ${#bb_new} == ${#re_rel} ]]
    then
        echoProcess "checkout $1 from remote starting"
        git checkout -b "$rel_new" "origin/$rel_new"
        if [[ $? -ne 0 ]]
        then
            echoError "checkout remote error. work:${curDirName},branch:${rel_new}"
            exit 2
        fi
    else
        echoProcess "there no branch:${rel_new},work:${curDirName}. now checkout master staring"
        defaultB="master"
        if [[ "$defaultB" == "$rel_new" ]]
        then
            echoError "there no master branch. must be check. work:${curDirName}"
            exit 2
        fi
        checkout_branch ${defaultB}
    fi
}

####pushBranch branchName
function pushBranch() {
    rel_push=$1
    p_work=$2
    cur_bb_check=`git symbolic-ref -q HEAD | cut -b 12-`
    if [[ "${cur_bb_check}" != "${rel_push}" ]]
    then
        echoError "push branch break. current branch not exists. work:${p_work},branch:$rel_push,current:${cur_bb_check}"
        return 1
    fi
    cur_bb_syn=`git symbolic-ref -q HEAD | cut -b 12-`
    isUpStream=`git bb -vv | grep ${cur_bb_syn} | grep -q "\[" && echo 1 || echo 0`
    if [[ ${isUpStream} -eq 0 ]]
    then
        echoInput "${p_work} current branch is a new branch, continue push to remote?(y or n)"
        read cmd_ps
        if [[ "y" == ${cmd_ps} ]]
        then
            echo ""
        else
            exit 2
        fi

        git push -u --progress origin ${rel_push}:${rel_push}
        if [[ $? -ne 0 ]]
        then
            echoError "push branch error. git error. work:${p_work},branch:$cur_bb_check"
            exit 2
        fi
        echoSuccess "push success. create new branch to remote. work:${p_work},branch:$cur_bb_check"
    else
        synRemote ${cur_bb_check}
        logMsgPs=`git log origin/${cur_bb_check}..${cur_bb_check}`
        if [[ -z "${logMsgPs}" ]]
        then
            echoProcess "push break. no commits. work:${p_work},branch:$cur_bb_check"
            return 0
        fi
        echo "======================================================================="
        git log --stat origin/${cur_bb_check}..${cur_bb_check}
        echoInput "${p_work}:${cur_bb_check}. please confirm will push commits,  continue push to remote?(y or n)"
        read cmd_ps
        if [[ "y" == ${cmd_ps} ]]
        then
            echo ""
        else
            exit 2
        fi
        if [[ "master" == ${cur_bb_check} ]]
        then
            echoInput "${p_work}:${cur_bb_check}. you are pushing master, please be careful!!! continue?(y or n)"
            read cmd_master
            if [[ "y" == "${cmd_master}" ]]
            then
                git push
                echoSuccess "push success. work:${p_work},branch:$cur_bb_check"
            else
                echoProcess "push break. you give up push master"
                return 0
            fi
        fi
        git push
        if [[ $? -ne 0 ]]
        then
            echoError "push branch error. git error. work:${p_work},branch:$cur_bb_check"
            exit 2
        fi
        echoSuccess "push success. work:${p_work},branch:$cur_bb_check"
    fi
}

####mergeBb baseBranch mergeBranch
function mergeBb() {
    m_baseB=$1
    m_mergeB=$2
    m_work=$3
    if [[ ${m_baseB} == ${m_mergeB} ]]
    then
        echoError "merge is unnecessary. branch is same. work:${m_work} branch:${m_baseB}"
        return 0;
    fi

    isContainB=`git branch | grep -wq ${m_baseB} && echo 1 || echo 0`
    isContainM=`git branch | grep -wq ${m_mergeB} && echo 1 || echo 0`
    if [[ ${isContainB} -eq 0 || ${isContainM} -eq 0 ]]
    then
        echoError "merge is unnecessary. not this branch. work:${m_work} branch:${m_baseB}"
        return 1
    fi

    m_curB=`git symbolic-ref -q HEAD | cut -b 12-`
    echoProcess "merge staring. baseBranch:${m_baseB},mergeBranch:${m_mergeB},work:${m_work}"
    if [[ ${m_baseB} != ${m_curB} ]]
    then
        git checkout ${m_baseB}
    fi
    echo "======================================================================================="
    logMsg=`git log ${m_baseB}..${m_mergeB}`
    if [[ -z "${logMsg}" ]]
    then
        echoInput "merge branch:${m_mergeB} to branch:${m_baseB} in work:${m_work}, no commits to merge. merge continue?(y or n)"
        read cmd_nlc
        if [[ "y" != "${cmd_nlc}" ]]
        then
            exit 2
        else
            return 0
        fi
    fi
    git log --stat ${m_baseB}..${m_mergeB}
    echoInput "merge branch:${m_mergeB} to branch:${m_baseB} in work:${m_work}, merge log is above,You must confirm commits is right with right branch. following options\nr:right,s:skip,e:exit"
    read logConfirm
    if [[ "r" == "${logConfirm}" ]]
    then
        echoProcess "merge log is right, will execute merge. ${m_mergeB} to branch:${m_baseB} "
    elif [[ "s" == "${logConfirm}" ]]
    then
        return 1
    else
        exit 2
    fi
    ##### master need tag
    if [[ "master" == "${m_baseB}" ]]
    then
        read -p "#${m_work}#you are merge branch:${m_mergeB} to ${m_baseB}. please input tag version :" tagVersion
        read -p "#${m_work}#you are merge branch:${m_mergeB} to ${m_baseB}. please input tag desc message :" tagMsg
        echoProcess "${m_work} ${m_mergeB} merge to ${m_baseB} tag message confirm. version:${tagVersion},message:${tagMsg}"
        git tag -a ${tagVersion} -m ${tagMsg}
        git push origin ${tagVersion}
    fi
    git merge ${m_mergeB}
    if [[ $? -ne 0 ]]
    then
        echoError "merge failed. You must solve it by hand. merge ${m_mergeB} to ${m_baseB} in work:${m_work}"
        echoInput "solve it by hand success. continue?(y or n)"
        read cmd_mm
        if [[ "y" != "${cmd_mm}" ]]
        then
            exit 2
        fi
    fi
    echoSuccess "merge success. merge ${m_mergeB} to branch:${m_baseB} in work:${m_work}"
}