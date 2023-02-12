# Check the system statistics for the last 3 days
for i in {1..3}
do
    date=$(date --date="-$i day" +%Y-%m-%d)
    day=$(date +%A -d "$date")
    sar -r -f /var/log/sa/sa$(date +%d -d "$date") > /tmp/meminfo.$date
    sar -u -f /var/log/sa/sa$(date +%d -d "$date") > /tmp/cpuinfo.$date
    sar -b -f /var/log/sa/sa$(date +%d -d "$date") > /tmp/diskinfo.$date

    # Check for anomalies in memory usage for each day
    awk -v day="$day" '
    BEGIN {
        anom=0
    }
    {
        if ($5 > 95) {
            anom=1
            printf("WARNING: %s %s %s %s\n", day, $1, $2, $5)
        }
    }
    END {
        if (anom == 1) {
            printf("\nAnomalies detected in memory usage for %s\n\n", day)
        } else {
            printf("\nNo anomalies detected in memory usage for %s\n\n", day)
        }
    }
    ' /tmp/meminfo.$date

    # Check for anomalies in CPU usage for each day
    awk -v day="$day" '
    BEGIN {
        anom=0
    }
    {
        if ($8 > 95) {
            anom=1
            printf("WARNING: %s %s %s %s\n", day, $1, $2, $8)
        }
    }
    END {
        if (anom == 1) {
            printf("\nAnomalies detected in CPU usage for %s\n\n", day)
        } else {
            printf("\nNo anomalies detected in CPU usage for %s\n\n", day)
        }
    }
    ' /tmp/cpuinfo.$date

    # Calculate IOPS for each day
    awk -v day="$day" '
    BEGIN {
        iops=0
    }
    {
        iops+=$4+$5
    }
    END {
        printf("\nIOPS for %s: %d\n\n", day, iops)
    }
    ' /tmp/diskinfo.$date
done

# Clean up temporary files
rm /tmp/meminfo.*
rm /tmp/cpuinfo.*
rm /tmp/diskinfo.*
