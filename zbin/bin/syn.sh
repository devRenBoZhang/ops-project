###########################################
####syn name [projects]
####
####
###########################################
#!/bin/bash

pushd $(dirname $0)/.. >/dev/null
BASE=$(pwd)
popd >/dev/null
cd ${BASE}

. ${BASE}/lib/config.sh
. ${BASE}/lib/fun_base.sh
. ${BASE}/lib/git-help/fun_git.sh

function describe() {
    echo -e "syn (选项) (分支名) \n\n【选项】\n
    -b参数:branch指定项目分支，以“:”分隔项目和分支；以“,”分隔项目【projectName:branchName,A:B】
    -e:edit编辑项目配置信息
    -l:local更新本地当前分支
    -p参数:projects指定项目，多个项目以“,”分隔
    -q:quiet减少日志输出
    -v:valid验证是否合并master
    -h:help帮助
    -w:激活指定工作目录,在work.properties配置配置
    "
}

function synArgsDesc() {
  if [[ "X${quietLog}X" != "XyX" ]]; then
    synArgsDesc="syn works args summary ######\n###### baseBranch:${branchName}"
    if [[ "XX" != "X${ass_syn_pro_workStr}X" ]]; then
      synArgsDesc="${synArgsDesc}\n###### works:${ass_syn_pro_workStr}"
    else
      synArgsDesc="${synArgsDesc}\n###### works:${syn_pro_str}"
    fi
    if [[ "XX" != "X${customWorkBra}X" ]]; then
      synArgsDesc="${synArgsDesc}\n###### customBranch:${customWorkBra##}"
    fi

    echoBase "${synArgsDesc}"
  fi
}
####
## 指定项目配置
##  active_work_pro active_alias_name
function active_work_pro() {
  active_s_work_name_f=$1
  if [[ "XX" == "X${active_s_work_name_f}X" ]]; then
    return 0
  fi
  active_s_works_f=($(getProConfigs ${active_s_work_name_f}))
  for w in ${active_s_works_f[*]}; do
    s_a_vars_1=${w%%:*}
    s_a_vars_2=${w##*:}
    if [[ "XX" == "X${s_a_vars_1}X" ]]; then
      continue
    elif [[ "active_name" == "${s_a_vars_1}" ]]; then
      active_name_s=${s_a_vars_1}
    elif [[ "default-branch" == "${s_a_vars_1}" ]]; then
      default_branch="${s_a_vars_2}"
    else
      s_a_isContain_p=$(echo ${customWorkBra} | grep -wq "${s_a_vars_1%%-project*}-project" && echo 1 || echo 0)
      if [[ ${s_a_isContain_p} -eq 0 ]]; then
        customWorkBra="${customWorkBra} ${s_a_vars_1%%-project*}-project:${s_a_vars_2}"
        ass_syn_pro_workStr="${ass_syn_pro_workStr},${s_a_vars_1}"
      fi
    fi
  done
  if [[ "XX" == "X${active_name_s}X" ]]; then
    echoError "not exists this work project active config. please check"
    exit 2
  fi

  if [[ "XX" == "X${default_branch}X" ]]; then
    default_branch="master"
  fi
  if [[ "XX" == "X${branchName}X" ]]; then
    branchName=${default_branch}
  fi
}

####
## synPro gitDir
function synPro() {
  work=$1
  work=${work##*/}
  work="${work%%-project*}-project"

  if [[ "XALLX" == "X${s_y_p_tag}X" ]]; then
    ass_syn_pro_workStr=""
  fi
  isContain=$(isContainWork ${work} ${ass_syn_pro_workStr})
  s_p_tag_all="y"
  if [[ "XyX" != "X${isContain}X" ]]; then
    return 1
  fi
  git status >/dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    echoWarn "${work} not a git repository, please check."
    return 1
  fi

  synBranchName=$(echo "${customWorkBra}" | grep ${work} | sed "s/.*${work}:\(\S\+\).*/\1/")
  if [[ "XX" == "X${synBranchName}X" ]]; then
    if [[ "XyX" == "X${synLocal}X" ]]; then
      synBranchName=$(git symbolic-ref -q HEAD | cut -b 12-)
    else
      synBranchName=${branchName}
    fi
  fi
  echoLocation "$work syn ${synBranchName} starting"
  checkout_branch ${synBranchName}
  if [[ $? -ne 0 ]]; then
    echoError "${work} syn error."
  else
    cur_cc_syn=$(git symbolic-ref -q HEAD | cut -b 12-)
    echoSuccess "${work} syn success. branch is in ${cur_cc_syn}"
    if [[ "X${synBranchName}X" == "X${cur_cc_syn}X" ]]; then
      synExactWorks="${synExactWorks} ${work}"
    fi
  fi

  #### merge master valid
  merge_master_diff=$(git log ..origin/master)
  if [[ -z "${merge_master_diff}" ]]; then
    return 1
  fi
  if [[ "XyX" != "X${master_diff_valid}X" ]]; then
    noMergeMasterWorks="${noMergeMasterWorks} ${work}"
    return 1
  fi
  git log ..origin/master --stat
  echoInput "work:${work} branch:${synBranchName} has not merge master. try merge safely? (y or n)"
  read mergeMasterSafe
  if [[ "XyX" == "X${mergeMasterSafe}X" ]]; then
    git merge origin/master
    if [[ $? -ne 0 ]]; then
      git reset --hard origin/${synBranchName} 2>/dev/null
      echoError "merge master error. please contact feature developer. "
      exit 2
    else
      echoSuccess "${work} merge master success"
    fi
  else
    noMergeMasterWorks="${noMergeMasterWorks} ${work}"
  fi
}

########################################################################################################################
#################### start shell
branchName="master"
# 无参数默认更新本分支
if [[ $# -lt 1 ]];then
    syn.sh -l
    exit 0
fi

TEMP=$(getopt -o "b:ehqp:vlw:" -n "syn.sh" -- "$@" 2>/dev/null)
if [[ $? != 0 ]]; then
  echoError "param error"
  describe
  exit 1
fi
eval set -- "${TEMP}"
while true; do
  case "$1" in
  -b)
    bAliasArgs=$2
    bAliasArray=(${bAliasArgs//,/ })
    for arg in ${bAliasArray[*]}; do
      workAlias=${arg%%:*}
      branchAlias=${arg##*:}
      if [[ "XX" == "X${workAlias}X" || "XX" == "X${branchAlias}X" || "X${branchAlias}X" == "X${workAlias}X" ]]; then
        echoError "option -b is Illegal, please check"
        describe
        shift 2
        exit 0
      fi
      customWorkBra="${customWorkBra} ${workAlias%%-project*}-project:${branchAlias}"
      customWorkAlias="${customWorkAlias},${workAlias%%-project*}-project"
    done
    shift 2
    ;;
  -e)
    vi ${BASE}/conf/work.properties
    shift
    exit 0
    ;;
  -h)
    describe
    shift
    exit 0
    ;;
  -q)
    quietLog="y"
    shift
    ;;
  -p)
    ass_syn_pro_workStr=$(getWorks $2)
    if [[ $? != 0 ]]; then
      exit 2
    fi
    if [[ "XX" == "X${ass_syn_pro_workStr}X" ]]; then
      echoError "assign syn project error. no this config. please check"
      exit 2
    fi
    if [[ "XallX" == "X${ass_syn_pro_workStr}X" ]]; then
      s_y_p_tag="ALL"
    fi
    shift 2
    ;;
  -v)
    master_diff_valid="y"
    shift
    ;;
  -l)
    synLocal="y"
    shift
    ;;
  -w)
    active_work_name=$2
    shift 2
    ;;
  --)
    shift
    break
    ;;
  *)
    echoError "param parse error"
    describe
    exit 1
    ;;
  esac
done

for arg; do
  args=${args}","${arg}
done
argArray=(${args//,/ })
branchName=${argArray[0]}

active_work_pro ${active_work_name}

if [[ "XX" == "X${branchName}X" && "XX" == "X${synLocal}X" ]]; then
  echoError "branch name is necessary"
  exit 2
fi

if [[ "XX" != "X${customWorkAlias}X" ]]; then
  customWorks=(${customWorkAlias//,/ })
  for w in ${customWorks[*]}; do
    w="${w%%-project*}-project"
    isContain=$(isContainWork ${w} ${ass_syn_pro_workStr})
    if [[ "XyX" != "X${isContain}X" ]]; then
      ass_syn_pro_workStr="${ass_syn_pro_workStr},${w}"
    fi
  done
fi
if [[ "XX" == "X${ass_syn_pro_workStr}X" ]]; then
  default_work_alias=$(getConfig "default_work_alias")
  if [[ "XX" == "X${default_work_alias}X" ]]; then
    default_work_alias="work"
  fi
  ass_syn_pro_workStr=$(getWorks ${default_work_alias})
fi

### syn git repository project
syn_gitReStr=$(getConfig "gitRep_dirs")
if [[ "XX" == "X${syn_gitReStr}X" ]]; then
  echoWarn "no config execute dir list. please check"
  exit 2
fi
syn_gitReps=(${syn_gitReStr//,/ })
for gitRep in ${syn_gitReps[*]}; do
  cd ${gitRep}
  syn_pro_str=$(getDirProjectNames)
  if [[ "XX" == "X${syn_pro_str}X" ]]; then
    echoWarn "${gitRep} no project found. please check"
    continue
  fi

  synArgsDesc

  syn_pro_work=(${syn_pro_str//,/ })
  for work in ${syn_pro_work[*]}; do
    cd "${gitRep}/$work"
    synPro $(pwd)
  done
done

### syn  special project
syn_gitProStr=$(getConfig "gitRep_pros")
if [[ "XX" != "X${syn_gitProStr}X" ]]; then
  syn_pro_str=""
  synPros=(${syn_gitProStr//,/ })
  for pro in ${synPros[*]}; do
    proName=${pro##*/}
    if [[ "XX" == "X${syn_pro_str}X" ]]; then
      syn_pro_str=${proName}
    else
      syn_pro_str="${syn_pro_str},${proName}"
    fi
  done
  synArgsDesc

  syn_pro_str=${syn_gitProStr}
  syn_pro_work=(${syn_pro_str//,/ })
  for work in ${syn_pro_work[*]}; do
    cd "$work"
    synPro $(pwd)
  done
fi

resultDesc="execute result summary ######"
if [[ "XX" != "X${noMergeMasterWorks}X" ]]; then
  echoError "these projects behind master [${noMergeMasterWorks}]"
fi
if [[ "XX" != "X${synExactWorks}X" ]]; then
  echoBase "these projects exists exact branch [${synExactWorks}]"
else
  echoError "these projects requires at least one branch to be right"
fi
