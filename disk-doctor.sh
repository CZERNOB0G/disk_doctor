#!/bin/bash
disks=();
disks_failed=();
tempera=();
for i in `seq 29 52`;
    do
        errors=`smartctl -A /dev/sdc -d megaraid,$i | grep -P 'Reallocated_Sector_Ct|Offline_Uncorrectable|Reported_Uncorrect|End-to-End_Error' | awk '{print $NF}' | awk '{sum+=$1} END {print sum}'`;
        temp=`smartctl -A /dev/sdc -d megaraid,$i | grep -P 'Airflow_Temperature_Cel' | awk -F'(' '{print $1}' | awk '{print $NF}'`;
        if [ -z $errors ];
            then
                smart_read="NULL!";
        fi
        temp=${temp:="1"};
        errors=${errors:="1"};
        if [ "$errors" -gt "0" -o -n "$smart_read" -o "$temp" -gt "50" ];
            then
                let inc++;
                disks_failed[$inc]=$i;
                if [ "$temp" -gt "50" ];
                    then
                        let tpm++
                        tempera[$i]="$temp";
                fi
                if [ "$errors" -gt "0" -a -z "$smart_read" ];
                    then
                        disks[$i]="$errors Errors";
                    else
                        disks[$i]="$smart_read";
                fi
        fi
        unset smart_read
        unset temp
done
if [ -z "$inc" -a -z "$tpm" ];
    then
        exit;
fi
for l in ${disks_failed[*]};
    do
        position=`raidstatus show disks | grep -m1 "Disk $l" | cut -d "[" -f2 | cut -d "]" -f1`;
        serial=`smartctl -a /dev/sdc -d megaraid,$l | grep Serial | cut -d ":" -f2 | tr -d '[:space:]'`;
        serial=${serial:="S/N"};
        position=${position:="S/N"};
        temperatura="${tempera[$l]}";
        temperatura=${temperatura:="1"};
        if [ "$temperatura" -gt "50" ];
            then
                if [ "$errors" -le "0" ];
                    then
                        echo "Disco $l - [$position] - $serial (+${tempera[$l]}*C)";
                    else
                        echo "Disco $l - [$position] - $serial - ${disks[$l]} (+${tempera[$l]}*C)";
                fi
            else
                echo "Disco $l - [$position] - $serial - ${disks[$l]}";
        fi
done
exit;
