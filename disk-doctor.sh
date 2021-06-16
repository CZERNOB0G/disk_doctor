#!/bin/bash
init="$1";
endt="$2";
ini=${init:="29"};
end=${endt:="52"};
disks_failed=()
echo "> Verificando smartctl (Aguarde!) "
for i in `seq $ini $end`; 
    do
        reallocated_Sector_t=`smartctl -A /dev/sdc -d megaraid,$i | grep -P 'Reallocated_Sector_Ct' | awk '{print $NF}'`;
        Offline_Uncorrectable_t=`smartctl -A /dev/sdc -d megaraid,$i | grep -P 'Offline_Uncorrectable' | awk '{print $NF}'`;
        Reported_Uncorrect_t=`smartctl -A /dev/sdc -d megaraid,$i | grep -P 'Reported_Uncorrect' | awk '{print $NF}'`;
        End_to_End_t=`smartctl -A /dev/sdc -d megaraid,$i | grep -P 'End-to-End_Error' | awk '{print $NF}'`;
        reallocated_Sector=${reallocated_Sector_t:="1"};
        Offline_Uncorrectable=${Offline_Uncorrectable_t:="1"};
        Reported_Uncorrect=${Reported_Uncorrect_t:="1"};
        End_to_End=${End_to_End_t:="1"};
        all_erros=`smartctl -A /dev/sdc -d megaraid,$i | grep -P 'Reallocated_Sector_Ct|Offline_Uncorrectable|Reported_Uncorrect|End-to-End_Error'`;
        if [ -z "$all_erros" -o "$reallocated_Sector" -gt "0" -o "$Offline_Uncorrectable" -gt "0" -o "$Reported_Uncorrect" -gt "0" -o "$End_to_End" -gt "0" ];
            then
                let inc_smart++;
                disks_failed[$inc_smart]=$i;
        fi
done
if [ -z "$inc_smart" -o ${#disks_failed[@]} -eq 0 ];    
    then
        echo "=========================="
        echo "= Não têm disco com erro ="
        echo "=========================="
        exit;
fi
echo "> Total de $inc_smart discos com problema!"
echo "> Verificando raidstatus (Aguarde!)"
raid_disks=()
for l in ${disks_failed[*]};
    do
        raid_fisico=`raidstatus show disks | grep -m1 "Disk $l" | cut -d "[" -f2 | cut -d "]" -f1`;
        serial=`smartctl -a /dev/sdc -d megaraid,$l | grep Serial | cut -d ":" -f2 | tr -d '[:space:]'`;
        raid_fisico_ofc=${raid_fisico:="SN"};
        serial_ofc=${serial:="SN"};
        echo " - Disco $l - [$raid_fisico_ofc] - $serial_ofc"
done
echo "> Teminado!"
exit;
