#!/bin/bash

LIST_A=""
LIST_B=""
LOG_FILE=${1}
rm -rf ${LOG_FILE}

for LINE in $(cat ${LOG_FILE} | grep -v "tools" |grep -v "Jenkinsfile")
do
if [[ ${LINE} =~ .*3rd-party.* ]]
then
   MODULE=$(echo ${LINE} | awk -F'/' '{print $2}')
   if [[ ! ${LIST_A} =~ .*${MODULE}.* ]] && [[ ! ${MODULE} =~ .*.xml.* ]]
   then
        LIST_A="${LIST_A} ${MODULE}"
   fi
else
   MODULE=$(echo ${LINE} | awk -F'/' '{print $1}')
   if [[ ! ${LIST_B} =~ .*${MODULE}.* ]] && [[ ! ${MODULE} =~ .*.xml.* ]]
   then
        LIST_B="${LIST_B} ${MODULE}"
   fi
fi

done

echo "LIST_A = ${LIST_A}"
echo "LIST_B = ${LIST_B}"