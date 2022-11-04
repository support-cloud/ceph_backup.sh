#!/bin/bash

array=()

## source openrc file ##
source open-rc

## Get Instance Name ###

GET_INSTANCE_NAMEs=$(openstack --insecure server list --all-projects --long | awk 'NR>=4 {print $4}')

## Match instance name and instance id ##

for i in $GET_INSTANCE_NAMEs; do
    VMID=$(openstack --insecure server list --all-projects --long | grep "$i" | awk '{print $2}');

    ## create VM name dir to stored by backup ##

    if [[ ! -e /root/"$i" ]]; then
        mkdir -p /root/"$i"
    fi
    ## check VM ID in ceph_rbd disk is similar continue to full backup ##
    for j in $VMID; do
        while IFS='' read -r line; do array+=("$line"); done < <(rbd ls -p vms | grep "$j"_disk)
             for ID in "${array[@]}"; do
                 for w in $(openstack --insecure server list --all-projects --long | grep "$i" | awk 'NR<=1 {print $6}')
                 do
                     if [ "$w" == "error" ];
                     then
                         echo "[INFO] $i is in error state... skipping"
                         break 1
                     elif [ "$ID" == "$j"_disk ] ;
                     then
                         rbd snap create vms/$ID@$ID && rm -rf /root/"$i"/"$ID".img && rbd export vms/$ID@$ID /root/"$i"/"$ID".img && rbd snap rm vms/$ID@$ID
                         continue
                     fi
                 done

             done
    done
done
