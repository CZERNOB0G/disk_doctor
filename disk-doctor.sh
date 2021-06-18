#!/bin/bash
servidor=`hostname`;
if [ $servidor = "box5" -o $servidor = "box6" -o $servidor = "bkp1" ];
    then
        echo " ";
        echo "========== Disk doctor 16-31 (box5|box6|bkp1) ==========";
        echo " ";
        ini="16";
        end="31";
    else
        echo " ";
        echo "========== Disk doctor 29-52 ==========";
        echo " ";
        ini="29";
        end="52";
fi
total_erros=();
disks_failed=();
echo "> Verificando smartctl (Aguarde!) ";
for i in `seq $ini $end`; 
    do
        all_erros=` smartctl -A /dev/sdc -d megaraid,$i | grep -P 'Reallocated_Sector_Ct|Offline_Uncorrectable|Reported_Uncorrect|End-to-End_Error' | awk '{print $NF}' | awk '{sum+=$1} END {print sum}'`;
        if [ -z $all_erros ];
            then
                $all_erros="1";
                null="Queimado!";
        fi
        if [ "$all_erros" -gt "0" -o -n "$null" ];
            then
                let inc_smart++;
                disks_failed[$inc_smart]=$i;
                if [ -z $null ];
                    then
                        total_erros[$i]="$all_erros Erros";
                    else
                        total_erros[$i]="$null";
                fi
        fi;
done;
if [ -z "$inc_smart" ];    
    then
        echo "==========================";
        echo "= Não têm disco com erro =";
        echo "==========================";
        exit;
fi
echo "> Total de $inc_smart discos com problema!";
echo "> Verificando raidstatus (Aguarde!)";
echo " ";
raid_disks=();
for l in ${disks_failed[*]};
    do
        raid_fisico=`raidstatus show disks | grep -m1 "Disk $l" | cut -d "[" -f2 | cut -d "]" -f1`;
        serial=`smartctl -a /dev/sdc -d megaraid,$l | grep Serial | cut -d ":" -f2 | tr -d '[:space:]'`;
        serial_ofc=${serial:="SN"};
        raid_fisico_ofc=${raid_fisico:="SN"};
        echo " Disco $l - [$raid_fisico_ofc] - $serial_ofc - ${total_erros[$l]}";
done;
echo " ";
echo "> Teminado!";
exit;
