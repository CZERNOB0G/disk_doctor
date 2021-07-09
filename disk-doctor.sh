#!/bin/bash
servidor=`hostname`;
if [ $servidor = "box5" -o $servidor = "box6" -o $servidor = "bkp1" ];
    then
        ini="16";
        end="31";
    else
        ini="29";
        end="52";
fi
total_erros=();
disks_failed=();
for i in `seq $ini $end`;
    do
        all_erros_t=`smartctl -A /dev/sdc -d megaraid,$i | grep -P 'Reallocated_Sector_Ct|Offline_Uncorrectable|Reported_Uncorrect|End-to-End_Error' | awk '{print $NF}' | awk '{sum+=$1} END {print sum}'`;
        if [ -z $all_erros_t ];
            then
                null="NULL!";
        fi
        all_erros=${all_erros_t:="1"};
        if [ "$all_erros" -gt "0" -o -n "$null" ];
            then
                let inc_smart++;
                disks_failed[$inc_smart]=$i;
                if [ -z $null ];
                    then
                        total_erros[$i]="$all_erros Errors";
                    else
                        total_erros[$i]="$null";
                fi
        fi
        unset null
done
if [ -z "$inc_smart" ];
    then
        exit;
fi
for l in ${disks_failed[*]};
    do
        raid_fisico=`raidstatus show disks | grep -m1 "Disk $l" | cut -d "[" -f2 | cut -d "]" -f1`;
        serial=`smartctl -a /dev/sdc -d megaraid,$l | grep Serial | cut -d ":" -f2 | tr -d '[:space:]'`;
        serial_ofc=${serial:="SN"};
        raid_fisico_ofc=${raid_fisico:="SN"};
        echo "Disco $l - [$raid_fisico_ofc] - $serial_ofc - ${total_erros[$l]}";
done
exit;
