#!/bin/bash

pushd `dirname $0`/.. > /dev/null
BASE=`pwd`
popd > /dev/null
cd ${BASE}

. ${BASE}/lib/config.sh
. ${BASE}/lib/fun_base.sh
. ${BASE}/lib/git-help/fun_git.sh
. ${BASE}/lib/mvn-help/fun_help.sh

#getRelativeDir "/d/GitRepository/ops-project/mvn/pl" "/d/GitRepository_ssh/trade-project"

getProConfigs "score-mall-B"
