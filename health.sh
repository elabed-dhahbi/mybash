function osdetail(){
        hostname -f &> /dev/null && printf "Hostname : $(hostname -f)" || printf "Hostname : $(hostname -s)"
        echo -en "\nOperating System : "
        [ -f /etc/os-release ] && echo $(egrep -w "NAME|VERSION" /etc/os-release|awk -F= '{ print $2 }'|sed 's/"//g') || cat /etc/redhat-release

        echo -e "Kernel Version :" $(uname -r)

        printf "OS Architecture :"$(arch | grep x86_64 &> /dev/null) && printf " 64 Bit OS\n" || printf " 32 Bit OS\n"
}

function systemuptime() {

#--------Print system uptime-------#

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

        #-----------Checking for readonly filesystem-------#
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

        # Check the load averages for the last week
        echo "Checking load averages for the last week..."
        sar -q | tail -n +2 | awk '$1 >= 7 {print "Day: "$1", Load average: "$4" "$5" "$6}'

        # Check the CPU utilization for the last week
        echo "Checking CPU utilization for the last week..."
        sar -u | tail -n +2 | awk '$1 >= 7 {print "Day: "$1", CPU utilization: "$3"%"}'

        # Check the memory utilization for the last week
        echo "Checking memory utilization for the last week..."
        sar -r | tail -n +2 | awk '$1 >= 7 {print "Day: "$1", Memory utilization: "$4"%"}'

        # Check the disk utilization for the last week
        echo "Checking disk utilization for the last week..."
        sar -d | tail -n +2 | awk '$1 >= 7 {print "Day: "$1", Disk utilization: "$3"%"}'

        # Check the network utilization for the last week
        echo "Checking network utilization for the last week..."
        sar -n DEV | tail -n +2 | awk '$1 >= 7 {print "Day: "$1", Network utilization: "$3"%"}'

}

function checkdisk(){

        # Set the device name of the hard disk
        disk="/dev/sda"

        # Check the SMART data of the hard disk
        echo "Checking SMART data for $disk..."
        smartctl -H $disk

        # Check for bad blocks on the hard disk
        echo "Checking for bad blocks on $disk..."
        badblocks -sv $disk

        # Check for file system errors on the hard disk
        echo "Checking for file system errors on $disk..."
        fsck $disk

        # Run a read-only diagnostic test on the hard disk
        echo "Running a read-only diagnostic test on $disk..."
        hdparm -tT $disk
}
function dofunction(){
        osdetail
        systemuptime
        readonlyfilesystem
        sarf
        swapf
        check_df
        check_du $DIR
        check_memory
        check_processor
        checkdisk
}
dofunction
