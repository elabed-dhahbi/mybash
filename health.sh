function osdetail(){
        hostname -f &> /dev/null && printf "Hostname : $(hostname -f)" || printf "Hostname : $(hostname -s)"

        # Check the current operating system
        if [ -f /etc/os-release ]; then
                # Extract the operating system name and version from /etc/os-release
                echo -en "\nOperating System : "
                echo $(egrep -w "NAME|VERSION" /etc/os-release|awk -F= '{ print $2 }'|sed 's/"//g')
        elif [ -f /etc/lsb-release ]; then
                # Extract the operating system name and version from /etc/lsb-release
                echo -en "\nOperating System : "
                echo $(egrep -w "DISTRIB_ID|DISTRIB_RELEASE" /etc/lsb-release | awk -F= '{ print $2 }' | sed 's/"//g')
        elif [ -f /etc/SuSE-release ]; then
                # Extract the operating system name and version from /etc/SuSE-release
                echo -en "\nOperating System : "
                echo $(egrep -w "NAME|VERSION" /etc/SuSE-release | awk -F= '{ print $2 }' | sed 's/"//g')
        else
                # If the operating system is not recognized, display the contents of /etc/redhat-release
                echo -en "\nOperating System : "
                cat /etc/redhat-release
        fi

        echo -e "Kernel Version :" $(uname -r)

        printf "OS Architecture :"$(arch | grep x86_64 &> /dev/null) && printf " 64 Bit OS\n" || printf " 32 Bit OS\n"
}

function systemuptime() {

        echo "#--------Print system uptime-------#"

        UPTIME=$(uptime)

        echo -en "System Uptime : "

        echo $UPTIME|grep day &> /dev/null

        if [ $? != 0 ]; then

                echo $UPTIME|grep -w min &> /dev/null && echo -en "$(echo $UPTIME|awk '{print $2" by "$3}'|sed -e 's/,.*//g') minutes" || echo -en "$(echo $UPTIME|awk '{print $2" by "$3" "$4}'|sed -e 's/,.*//g') hours"

        else

                echo -en $(echo $UPTIME|awk '{print $2" by "$3" "$4" "$5" hours"}'|sed -e 's/,//g')

        fi

echo -e "\nCurrent System Date & Time : "$(date +%c)
}
function readonlyfilesystem(){

        echo "#-----------Checking for readonly filesystem-------#"
        readonly_fs=$(df -P | awk '{if ($6 == "ro") print $1}')
        if [ -n "$readonly_fs" ]; then
                 echo "The following filesystems are read-only:"
                 echo "$readonly_fs"
        else
        echo "No read-only filesystems detected."
        fi
}

function zombie() {

        zombie_processes=$(ps aux | awk '{if ($8 == "Z") print $2 " " $11}')
        if [ -n "$zombie_processes" ]; then
                echo "The following zombie processes were detected:"
                echo "$zombie_processes"
        else
                 echo "No zombie processes detected."
        fi
}
function swapf(){

        echo -e "\n\nChecking SWAP Details"

        echo -e "$D"

        echo -e "Total Swap Memory in MiB : "$(grep -w SwapTotal /proc/meminfo|awk '{print $2/1024}')", in GiB : "$(grep -w SwapTotal /proc/meminfo|awk '{print $2/1024/1024}')

        echo -e "Swap Free Memory in MiB : "$(grep -w SwapFree /proc/meminfo|awk '{print $2/1024}')", in GiB : " $(grep -w SwapFree /proc/meminfo|awk '{print $2/1024/1024}')

}
function check_df() {
        #check the system if it is RHE5 or above
        RL=$(awk '{print $7}' /etc/redhat-release |cut -d "." -f1)
        if [[ $RL -gt 6 ]]
        then
                df -Th |awk '/^\/dev*/ {print $6"\t"$7}' |awk 'gsub("%","",$1)  { print }'|awk '{if ($1>80) print $1"%\t"$2}'
                DIR=$(df -Th |awk '/^\/dev*/ {print $6"\t"$7}' |awk 'gsub("%","",$1)  { print }'|awk '{if ($1>80) print $1"%\t"$2}'|cut -d "%" -f2)
         else
                df -Th |awk '!/^\/dev*/ {print $5"\t"$6}' |awk 'gsub("%","",$1)  { print }'|awk '{if ($1>80) print $1"%\t"$2}'
                DIR=$(df -Th |awk '!/^\/dev*/ {print $5"\t"$6}' |awk 'gsub("%","",$1)  { print }'|awk '{if ($1>80) print $1"%\t"$2}'|awk -F "/" '{print $2}')
        fi
}

function check_du() {
        for dir in $1
        do
            cd  /$dir
            SPC=$(du -Ph --max-depth 1 . |cut -d " " -f1 |awk '/^[0-9]*.*G/ {print $1}'|cut -d 'G' -f1)
            for spc in $SPC
            do
                SPC_DIR=$(du -Ph --max-depth 1 .|awk -F "/" '/'$spc\G'/ {print $2} ')
                echo "for the /$SPC_DIR/  pleas try to check these following directories...."
                du -Ph --max-depth 3 |awk '/'$SPC_DIR'/'  |egrep '*[0-9]G'
             done
        done
}
#function to check available memory
function check_memory() {
  # Get the total memory and available memory in gigabytes
  total_memory=$(free -g | grep Mem | awk '{print $2}')
  available_memory=$(free -g | grep Mem | awk '{print $7}')

  # Calculate the percentage of memory that is free
  memory_percentage=$(awk "BEGIN {print $available_memory / $total_memory * 100}")

  # Check if less than 10% of the memory is free
  if [ $(echo "$memory_percentage < 5" | bc) -eq 1 ]; then
    echo "Warning: Less than 5% of memory is free on hoste `hostname`"
  else
    echo "There is sufficient memory available on hoste `hostname`"
  fi
}

# Call the function to check the available
#function to check processor utilization
function check_processor() {
# Set the threshold for the warning message
  threshold=90
# Set the time interval to check the processor utilization
  interval=60
  usage=$(mpstat 1 1 | grep -A 1 "Average:" | tail -1 | awk '{print $3}')
  if [ $(echo "$usage < $threshold" | bc) -eq 1 ]
  then
      echo "Procesor utilization is normal no need for investigation"
  else


          # Use the mpstat command to get the processor utilization
          utilization=$(mpstat $interval 1 | grep -A 1 "Average:" | tail -1 | awk '{print $3}')

          # Check if the processor utilization is above the threshold
          if [ $(echo "$utilization > $threshold" | bc) -eq 1 ]; then
             echo "Warning: Processor utilization is above $threshold% for more than $interval seconds"
          else
             echo "Processor utilization is normal"
          fi
  fi
}

# Call the function to check the processor utilization
function sarf(){

        # Calculate the average load average for the last two days
        echo "Calculating average load average for the last two days..."
        sar -q | tail -n +2 | awk '$1 >= 1 {sum1+=$4; sum2+=$5; sum3+=$6; count+=1} END {printf "Average load average: %.2f %.2f %.2f\n", sum1/count, sum2/count, sum3/count}'

        # Calculate the average CPU utilization for the last two days
        echo "Calculating average CPU utilization for the last two days..."
        sar -u | tail -n +2 | awk '$1 >= 1 {sum+=$3; count+=1} END {printf "Average CPU utilization: %.2f%%\n", sum/count}'

        # Calculate the average memory utilization for the last two days
        echo "Calculating average memory utilization for the last two days..."
        sar -r | tail -n +2 | awk '$1 >= 1 {sum+=$4; count+=1} END {printf "Average memory utilization: %.2f%%\n", sum/count}'

        # Calculate the average disk utilization for the last two days
        echo "Calculating average disk utilization for the last two days..."
        sar -d | tail -n +2 | awk '$1 >= 1 {sum+=$3; count+=1} END {printf "Average disk utilization: %.2f%%\n", sum/count}'

        # Calculate the average network utilization for the last two days
        echo "Calculating average network utilization for the last two days..."
        sar -n DEV | tail -n +2 | awk '$1 >= 1 {sum+=$3; count+=1} END {printf "Average network utilization: %.2f%%\n", sum/count}'

}
function demassage(){
        echo "-----------------Demsg command scan--------------------"
        echo "Checking for kernel panics or other serious errors..."
        dmesg | grep -i "panic\|Oops\|error"
        if [ $? -ne 0 ]; then
        echo "No kernel panics or other serious errors found."
        fi

        # Check for hardware issues
        echo "Checking for hardware issues..."
        dmesg | grep -i "disk\|memory\|cpu"
        if [ $? -ne 0 ]; then
        echo "No hardware issues found."
        fi

        # Check for system boot issues
        echo "Checking for system boot issues..."
        dmesg | grep -i "boot\|init\|systemd"
        if [ $? -ne 0 ]; then
        echo "No system boot issues found."
        fi

}

function checkdisk(){
        # Check the system logs for error messages related to disk failure
        echo "Checking system logs for error messages related to disk failure..."
        grep -i "disk\|lvm\|physical volume" /var/log/messages | grep -i "error\|fail\|down"


        # Use the pvscan command to check the status of physical volumes
        echo "Checking the status of physical volumes..."
        pvscan -s

        # Use the vgdisplay command to check the status of volume groups
        echo "Checking the status of volume groups..."
        vgdisplay -s

        # Use the lvs command to check the status of logical volumes
        echo "Checking the status of logical volumes..."
        lvs -o +devices

        # Run the check_logs function

}
function list_of_interfaces(){
interfaces=$(ip -o -4 addr | awk '{print $2}')

# Loop through the list of interfaces
for interface in $interfaces; do
  # Get the IP address of the interface
  ip=$(ip -o -4 addr show "$interface" | awk '{print $4}')

  # Print the interface and IP address
  printf "Interface: %s\tIP Address: %s\n" "$interface" "$ip"
done
}
function crontabfn(){
#check if the crontab command is available
if ! [ -x "$(command -v crontab)" ]; then
  echo "Error: crontab command not found" >&2
  exit 1
fi

# Get a list of all non-standard users (i.e., users with UIDs greater than 1000)
users=$(awk -F: '$3 > 1000 { print $1 }' /etc/passwd)

# Check the crontab for each user
for user in $users; do
  echo "Checking crontab for $user..."
  crontab -u $user -l
  if [ $? -ne 0 ]; then
    echo "No crontab for $user"
  fi
done

}
CheckUserhealth(){

# Get a list of all users in the password file
all_users=$(cut -d: -f1 /etc/passwd)

# Get a list of system users
system_users=$(awk -F: '($3 < 1000) { print $1 }' /etc/passwd)

# Initialize an array to store non-standard users
non_standard_users=()

# Loop through the list of all users
for user in $all_users; do
  # Check if the user is a system user
  if [[ ! "$system_users" =~ "$user" ]]; then
    # Add the user to the list of non-standard users
    non_standard_users+=("$user")
  fi
done

# Check if there are any non-standard users
if [ ${#non_standard_users[@]} -eq 0 ]; then
  # No non-standard users
  echo "This server has no non-standard users or sicap users."
else
  # Display the list of non-standard users
  echo "This server has the following non-standard or sicap users: ${non_standard_users[*]}"
fi

# List of users to check
users=("jboss" "mam" "stg" "psm" "mmg" "sls" "smppc" "smpps" "smppcs" "dmc")

# Loop through the list of users
for user in "${users[@]}"; do
  # Check if user exists
  if id -u "$user" > /dev/null 2>&1; then
    # Switch to user and run the 'ctl status all' command
    su - "$user" -c 'ctl status all'
  fi
done

}
#!/bin/bash

#!/bin/bash

function elasticsearch_health_check {
    # Get hostname
    hostname=$(hostname)

    # Check if Elasticsearch user exists
    if id "elasticsearch" >/dev/null 2>&1; then
        # Elasticsearch user exists, perform health check
        health=$(curl -XGET "$hostname:9200/_cluster/health")
        indices=$(curl -XGET "$hostname:9200/_cat/indices?v")
        nodes=$(curl -XGET "$hostname:9200/_cat/nodes?v")

        echo "Elasticsearch health: $health"
        echo "Indices:"
        echo "$indices"
        echo "Nodes:"
        echo "$nodes"

        # Check if any indices are in a "read" state
        read_indices=$(echo "$indices" | grep "read" | awk '{print $3}')
        if [ -z "$read_indices" ]; then
            echo "No indices are in a read state"
        else
            echo "Indices in read state: $read_indices"
        fi
    else
        # Elasticsearch user does not exist
        echo "Elasticsearch user does not exist"
    fi
}

function cluster(){

# Check the ID and release version of the operating system
id=$(lsb_release -i | awk '{ print $3 }')
release=$(lsb_release -r | awk '{ print $2 }' | cut -d'.' -f1)

# Display the cluster status using the appropriate command
if [[ $id == "RedHatEnterpriseServer" ]]; then
        if [[ $release -le 6 ]]; then
                # Use the clustat command
                clustat
        elif [[ $release -gt 6 ]]; then
                # Use the pcs command
                pcs status
        fi
elif [[ $id == "Debian" || $id == "SUSE" ]]; then
        # Use the crm_mon command
        crm_mon -1
else
        # Unsupported operating system
        echo "Error: Unsupported operating system"
fi


}
function timecheck(){
#!/bin/bash

# Check various time-related settings on the system

# Check the time zone
echo "Time zone: $(cat /etc/timezone)"

# Check the local time
echo "Local time: $(date)"

# Check the RTC time
echo "RTC time: $(hwclock -r)"

# Check if NTP is enabled
ntp_enabled=$(systemctl is-active ntpd)
if [ "$ntp_enabled" == "active" ]; then
  echo "NTP is enabled"
else
  echo "NTP is not enabled"
fi

# Check if NTP is synchronized
ntp_synchronized=$(ntpq -p | grep "*")
if [ -n "$ntp_synchronized" ]; then
  echo "NTP is synchronized"
else
  echo "NTP is not synchronized"
fi

# Check if DST is active
dst_active=$(timedatectl | grep "DST" | awk '{print $3}')
if [ "$dst_active" == "yes" ]; then
  echo "DST is active"
else
  echo "DST is not active"
fi

}


function dofunction(){
        osdetail
        timecheck
        systemuptime
        readonlyfilesystem
        sarf
        demassage
        list_of_interfaces
        swapf
        check_memory
        check_processor
        checkdisk
        cluster
        crontabfn
        CheckUserhealth
        elasticsearch_health_check
}
dofunction
