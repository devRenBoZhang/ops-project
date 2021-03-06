#!/bin/bash

pushd $(dirname $0)/.. >/dev/null
BASE=$(pwd)
popd >/dev/null
cd ${BASE}

. ${BASE}/lib/config.sh
. ${BASE}/lib/fun_base.sh
. ${BASE}/lib/git-help/fun_git.sh
. ${BASE}/lib/mvn-help/fun_help.sh

pomDir=$(getConfig "pomDir")

function describe() {
    echo -e "nb  (选项) (项目名称<多个直接以" "分隔>) (mvn phase<clean install deploy...>) \n\n【选项】\n-a参数:mvn am option \n-b参数:mvn branch, if not exists then mater \n
    -D参数:mvn args \n-f:flush pom modules by type\n-h:help帮助\n-s:编译常用服务\n-P参数:mvn p options \n-r参数:mvn ref options\n-t参数:mvn type in install,deploy,pl\n"
}

function activeWorkProject() {
  w_a_m_work=$1
  if [[ "XX" == "X${w_a_m_work}X" ]]; then
    return 0
  fi

  active_m_works=($(getProConfigs ${active_m_work_arg}))
  for w in ${active_m_works[*]}; do
    a_vars_1=${w%%:*}
    a_vars_2=${w##*:}
    if [[ "XX" == "X${a_vars_1}X" || "active_name" == "${a_vars_1}" || "default-branch" == "${a_vars_1}" ]]; then
      continue
    fi
    w_a_m_git_dir="${w_a_m_git_dir},${a_vars_1%%-project*}-project"
  done
  m_pl_custom_work="${m_pl_custom_work},${w_a_m_git_dir}"
}
function basePomUpdate() {
  if [[ "XX" == "X${m_pl_custom_work}X" ]]; then
    return 0
  fi
  cat pom.xml >pom_tmp.xml

  m_pl_delete_work_s=""
  m_pl_custom_works=(${m_pl_custom_work//,/ })
  m_pl_d_pom_w=($(cat pom.xml | awk -F "<module>|</module>" '{if(""!=$2){print $2}}'))
  for pl_d_v in ${m_pl_d_pom_w[*]}; do
    m_delte_y_n="y"
    for m_pl_c_v in ${m_pl_custom_works[*]}; do
      m_pl_c_w_v=$(echo ${pl_d_v} | grep -wq "${m_pl_c_v%%-project*}-project" && echo 1 || echo 0)
      if [[ ${m_pl_c_w_v} -ne 0 ]]; then
        m_delte_y_n="n"
        break
      fi
    done
    if [[ "XyX" == "X${m_delte_y_n}X" ]]; then
      m_pl_delete_work_s="${m_pl_delete_work_s},${pl_d_v}"
    fi
  done
  m_pl_delete_works=(${m_pl_delete_work_s//,/ })

  for w in ${m_pl_delete_works[*]}; do
    w=${w##*/}
    if [[ "XX" == "X#{w}X" ]]; then
      continue
    fi
    sed -i "/${w}/d" pom.xml
  done
}

########################################################################################################################
#################### start shell

mvnActiveP="runtime"
mvnD="skipTests"
mvnPl="-pl"
TEMP=$(getopt -o "a:b:D:fhsp:P:r:t:w:" -n "mav.sh" -- "$@" 2>/dev/null)
if [[ $? != 0 ]]; then
  echoError "param error"
  describe
  exit 1
fi
eval set -- "${TEMP}"
while true; do
  case "$1" in
  -a)
    am=$2
    shift 2
    ;;
  -b)
    branch=$2
    shift 2
    ;;
  -D)
    mvnD=$2
    shift 2
    ;;
  -f)
    flush="y"
    shift
    ;;
  -h)
    describe
    shift
    exit 0
    ;;
  -s)
    type="pl"
    projectName=$(getConfig "dailyService")
    shift
    ;;
  -p)
    m_pl_custom_work_arg=$2
    m_pl_custom_work_args=(${m_pl_custom_work_arg//,/ })
    for v in ${m_pl_custom_work_args[*]}; do
      m_pl_custom_work="${m_pl_custom_work},${v%%-project*}-project"
    done
    shift 2
    ;;
  -P)
    mvnActiveP=$2
    shift 2
    ;;
  -r)
    rf=$2
    shift 2
    ;;
  -t)
    type=$2
    shift 2
    ;;
  -w)
    active_m_work_arg=$2
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

if [[ "XyX" == "X${flush}X" ]]; then
  echoProcess "reloadModules starting"
  reloadModules "pl"
  reloadModules "mav"
  if [[ "XX" == "X${type}X" ]]; then
    reloadModules "install"
    reloadModules "deploy"
  elif [[ "XplX" != "X${type}X" && "XmavX" != "X${type}X" ]]; then
    reloadModules ${type}
  fi
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
"pl" | "install" | "deploy") ;;

*)
  echoError "not this type, please check."
  describe
  exit 2
  ;;
esac

if [[ "XX" != "X${rf}X" ]]; then
  cd ${pomDir}/pl
  mvnRf=$(grep "${rf}" pom.xml | cut -d ">" -f 2 | cut -d "<" -f 1)
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
  proArrays=(${projectName//,/ })
  for VAR in ${proArrays[*]}; do
    mvProPl="${mvProPl},"$(grep "${VAR}" pom.xml | awk -F '<module>|</module>' '{if(""!=$2){print $2}}')
  done
  mvProPl=${mvProPl#,}
  if [[ "X${globals}X" == "XX" ]]; then
    globals="clean install"
  fi
  cd ${pomDir}/mav

  if [[ "XX" != "X${active_m_work_arg}X" ]]; then
    activeWorkProject "${active_m_work_arg}"
  fi
  basePomUpdate

  ;;
*)
  echoError "no this type. please check"
  shift 2
  ;;
esac

echoProcess "mvn ${globals} ${mvnPl} ${mvProPl} -am ${mvnRf} -P${mvnActiveP} -D${mvnD}"

mvn ${globals} ${mvnPl} ${mvProPl} -am ${mvnRf} -P${mvnActiveP} -D${mvnD} 

if [ -f pom_tmp.xml ]; then
  cat pom_tmp.xml >pom.xml
  rm -rf pom_tmp.xml 2>/dev/null
fi
