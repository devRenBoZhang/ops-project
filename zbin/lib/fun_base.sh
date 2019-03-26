#!/bin/bash
function getWorks(){
    if [[ $# -lt 1 ]]
    then
        echoError "get works error. please input work type name"
        exit 2
    fi
    str="$1"
	configWorks=`getConfig ${str}`
	if [[ "XX" != "X${configWorks}X" ]]; then
	    str=${configWorks}
	fi
	echo ${str}
}
function getDirProjectNames(){
    excludeGitRepStr=`getConfig "excludeGitRep"`
    excludeGitRep=(${excludeGitRepStr//,/ })
   dirProjectNameCmd='ls -l | grep ^d.*$'
	for excPro in ${excludeGitRep[*]}
	do
	  dirProjectNameCmd=${dirProjectNameCmd}' | grep -vE "^.*'${excPro}'.*"'
	done
	dirProjectNames=`eval ${dirProjectNameCmd} | awk '{pro=pro","$9}END{print pro}'`
	echo ${dirProjectNames}
}
function getRelativeDir(){
    initDir=$1
    relativeDir=$2
    if [[ "X${initDir}X" == "X${relativeDir}X" ]]; then
        echo "."
        return 1
    fi
    initNum=`echo ${initDir} | awk -F "/" '{print NF}'`
    relativeNum=`echo ${relativeDir} | awk -F "/" '{print NF}'`
    shortNum=${initNum}
    if [[  ${initNum} > ${relativeNum} ]]; then
        shortNum=${relativeNum}
    fi
    initDirArray=(${initDir//\// })
    relativeArray=(${relativeDir//\// })
    commonDir=""
    for (( VAR = 0; VAR < ${shortNum}; ++VAR )); do
        if [[ "X${initDirArray[VAR]}X" ==  "X${relativeArray[VAR]}X" ]]; then
            commonDir="${commonDir}/${initDirArray[VAR]}"
        else
            relativePath="${initDir##*${commonDir}}"
            if [[ -z ${relativePath} || "X/X" == "X${relativePath}X" ]]; then
               relativePath="."
            fi
            relativePath=`echo "${relativePath}" | sed 's/\/[^\/]\+/\/../g'`
            relativePath=`echo ${relativePath} | sed 's/^\///'`
            echo "${relativePath}${relativeDir##*${commonDir}}"
            break
        fi
    done
}
function isContainWork(){
    work_c=$1
    work_c=${work_c##*/}
    work_c="${work_c%%-project*}-project"
    work_c_str=$2
    isContain="n"
	if [[ "XX" == "X${work_c_str}X" ]]; then
	  isContain="y"
    else
	  work_c_array=(${work_c_str//,/ })
      for s_w in ${work_c_array[*]}
	  do
	    s_w="${s_w%%-project*}-project"
	    if [[ "X${work_c}X" == "X${s_w}X" ]]; then
		    isContain="y"
		    break
	    fi
      done
	fi
	echo ${isContain}
}
function getCurDirName(){
    curPath=`pwd`;
    echo ${curPath##*/}
}
function echoError(){
    #### 红色
    echo -e "\033[;31;1m$* !!! \033[0m" >&2;
}

function echoWarn(){
    #### 黄色
    echo -e "\033[;33;1m###### $* !!! \033[0m" >&1;
}
function echoSuccess(){
    #### 蓝色
    echo -e "\033[;34;1m###### $* >>>>>>>>>>> \033[0m" >&1;
}

function echoBase(){
    #### 红色
    echo -e "\033[;32;1m##############################################################################################################   \033[0m" >&1;
    echo -e "\033[;32;1m###### $*  \033[0m" >&1;
    echo -e "\033[;32;1m##############################################################################################################   \033[0m" >&1;
}
function echoLocation(){
    #### 紫色
    echo -e "\033[;35;1m****** $* ************ \033[0m" >&1;
}

function echoProcess(){
    #### 天蓝色
    echo -e "\033[;36;1m$* ................. \033[0m" >&1;
}
function echoInput(){
    #### 红色
    echo -e "\033[;31;1m$* : \033[0m" >&1;
}