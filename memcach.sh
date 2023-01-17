OPTION=${1}
PROCESS="${@:2}"

if [[ ${OPTION} == "--service" ]]
then

        if [[  -z ${PROCESS} ]]
        then
                echo "you have to give a name of process"
        else
                for EXPRESSION in $(echo ${PROCESS})
                do
                        RAMUSAGE=$(ps -ely |awk -v process=${EXPRESSION} '$13 ==process' |awk '{SUM += $8/1024} END {print SUM}' |awk -F "." '{print $1}')
                        if [[ -z ${RAMUSAGE} ]]
                        then
                                echo " the process ${EXPRESSION} doesn't exist"
                        else
                                echo "RAM consumed by ${EXPRESSION} : ${RAMUSAGE} MB"
                        fi
                done
        fi
elif [[ ${OPTION} = "--pid" ]]
then
        if  [[ -z ${PROCESS} ]]
        then
                echo " Enter the number of process id(s)"
        else
                for EXPRESSION in $(echo ${PROCESS})
                do
                        RAMUSAGE=$(ps -ely |awk -v pid=${EXPRESSION} '$3 ==pid' |awk '{SUM += $8/1024} END {print SUM}' |awk -F "." '{print $1}')
                        SERVICE=$(ps -ely |awk -v pid=${EXPRESSION}  '$3 ==pid' |awk '{print $13}')

                        if [[ -z ${RAMUSAGE} ]]
                        then
                                echo "this pid ${EXPRESSION} do not exist"
                        else
                                echo " RAM consumption of the pid ${EXPRESSION} (${SERVICE})  : ${RAMUSAGE} MB"
                        fi
                done
        fi

elif [[ ${OPTION} = "--user" ]]
then
        if [[ -z ${PROCESS} ]]
        then
                echo " please provide me with the username"
        else
                for EXPRESSION in $(echo ${PROCESS})
                do
                        RAMUSAGE=$(ps -elyf |awk -v user=${EXPRESSION} '$2 == user' |awk '{SUM += $8/1024} END {print SUM}' |awk -F "." '{print $1}')
                        if [[ -z ${RAMUSAGE} ]]
                        then
                                echo " the user ${EXPRESSION} do not exist or is not using memory at the moment"
                        else
                                echo "RAM consumption for this user ${EXPRESSION}  : ${RAMUSAGE} MB"
                        fi
                done
        fi
fi
