#!/bin/sh

usage="Usage: snapshot-volume.sh <volume-path>"

volume_path=$1

if [ ! -e "$volume_path" ]; then
    echo "volume-path not given or does not exist!";
    echo $usage;
    exit 1;
fi;

volume_name=`lvdisplay "$volume_path"  | sed -n -e"s/^.*LV\ Name\s*\([A-Za-z0-9\-]*\)$/\1/pg"`
vg_path=`echo "$volume_path" | sed -n -e "s/\(.*\)\/[a-zA-Z0-9\-]*/\1/pg"`

active_snapshot=`lvdisplay | grep "LV snapshot status" | sed -n -e"s/.*active\ destination\ for\ \(.*\)$/\1/pg"`
if [ "$active_snapshot" != "" ]; then
    echo "Snapshot exists for $active_snapshot"
    exit 1;
fi;

snapshot_volume_name="${volume_name}-snapshot"

# I should try to calculate the size of the snapshot volume, but for now,
# we always create a 10G snapshot. 
# If left around, this might fill up!

/sbin/lvcreate -L10G -s -n "${snapshot_volume_name}" "$volume_path"
