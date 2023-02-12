#!/bin/bash

# Check the system statistics for the last 7 days
for i in {1..7}
do
    date=$(date --date="-$i day" +%Y-%m-%d)
    day=$(date +%A -d "$date")
    sar -r -f /var/log/sa/sa$(date +%d -d "$date") > /tmp/meminfo.$date

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
done

# Clean up temporary files
rm /tmp/meminfo.*
