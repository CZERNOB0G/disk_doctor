#!/bin/bash
bkbox=`hostname | grep -P 'box*|bkp*'`
if [ -z $bkbox ];
    then
        for l in $(eval echo {a..c});
            do
                hd=`lsblk -d -o name,rota | awk 'NR>1' | grep sd$l | grep -o 1`;
                if [ -n "$hd" ];
                    then
                        all_errors=`smartctl -A /dev/sd$l | grep -P 'Reallocated_Sector_Ct|Offline_Uncorrectable|Reported_Uncorrect|End-to-End_Error' | awk '{print $NF}' | awk '{sum+=$1} END {print sum}'`;
                        if [ -z $all_errors ];
                            then
                                null="NULL!";
                        fi
                        all_errors=${all_errors:="1"};
                        if [ "$all_errors" -gt "0" ];
                            then
                                serial=`smartctl -a /dev/sd$l | grep Serial | cut -d ":" -f2 | tr -d '[:space:]'`;
                                serial=${serial:="NULL"};
                                if [ -z $null ];
                                    then
                                        echo "sd$l - $serial - $all_errors Errors"
                                    else
                                        echo "sd$l - $serial - $null"
                                fi
                        fi
                        unset all_errors
                        unset null
                fi
            done
    else
        total_erros=();
        disks_failed=();
        for i in `seq 29 52`;
            do
                all_errors=`smartctl -A /dev/sdc -d megaraid,$i | grep -P 'Reallocated_Sector_Ct|Offline_Uncorrectable|Reported_Uncorrect|End-to-End_Error' | awk '{print $NF}' | awk '{sum+=$1} END {print sum}'`;
                if [ -z $all_errors ];
                    then
                        null="NULL!";
                fi
                all_erros=${all_errors:="1"};
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
fi
exit;
