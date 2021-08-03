#!/bin/bash
disks=();
disks_failed=();
for i in `seq 29 52`;
    do
        errors=`smartctl -A /dev/sdc -d megaraid,$i | grep -P 'Reallocated_Sector_Ct|Offline_Uncorrectable|Reported_Uncorrect|End-to-End_Error' | awk '{print $NF}' | awk '{sum+=$1} END {print sum}'`;
        if [ -z $errors ];
            then
                smart_read="NULL!";
        fi
        errors=${errors:="1"};
        if [ "$errors" -gt "0" -o -n "$smart_read" ];
            then
                let inc++;
                disks_failed[$inc]=$i;
                if [ -z $smart_read ];
                    then
                        disks[$i]="$errors Errors";
                    else
                        disks[$i]="$smart_read";
                fi
        fi
        unset smart_read
done
if [ -z "$inc" ];
    then
        exit;
fi
for l in ${disks_failed[*]};
    do
        position=`raidstatus show disks | grep -m1 "Disk $l" | cut -d "[" -f2 | cut -d "]" -f1`;
        serial=`smartctl -a /dev/sdc -d megaraid,$l | grep Serial | cut -d ":" -f2 | tr -d '[:space:]'`;
        serial=${serial:="S/N"};
        position=${position:="S/N"};
        echo "Disco $l - [$serial] - $serial - ${disks[$l]}";
done
exit;
