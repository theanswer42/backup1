#!/bin/sh

volume_group_path=$1
if [ "$volume_group_path" = "" ]; then
    echo "must give volume_group_path where snapshot exists"
    exit 1;
fi;

snapshot_volume_path=`lvdisplay "$volume_group_path" | sed -n -e"s/^.*LV\ Path\s*\([0-9a-zA-Z/\-]\+-snapshot\)$/\1/pg" | tail -1`
snapshot_volume_name=`lvdisplay "$snapshot_volume_path" | sed -n -e"s/^.*LV\ Name\s*\([0-9a-zA-Z/\-]\+-snapshot\)$/\1/pg"`
volume_open=`lvdisplay "$snapshot_volume_path" | sed -n -e "s/^.*# open\s*\([0-9]\+\)$/\1/pg"`

if [ "$volume_open" != "0" ]; then
    echo "$snapshot_volume_path is already open. Please close it first."
    exit 1;
fi;

snap_used=`df /snapshot --output="target,used" | sed -n -e "s/^\/snapshot\s\+\([0-9]\+\)$/\1/gp"`

if [ "$snap_used" != "" ]; then
    echo "Something is mounted at /snapshot."
    exit 1;
fi;

mount -o ro "$snapshot_volume_path" /snapshot;

snap_used=`df /snapshot --output="target,used" | sed -n -e "s/^\/snapshot\s\+\([0-9]\+\)$/\1/gp"`
if [ "$snap_used" = "" ]; then
    echo "could not mount /snapshot... something went wrong."
    exit 1;
fi;

# /backup must exist as a separate mount point and must have enough
# disk space.
free_blocks=`df /backup --output="target,avail" | sed -n -e "s/^\/backup\s\+\([0-9]\+\)$/\1/gp"`

if [ "$free_blocks" = "" -a $free_blocks -gt $snap_used ]; then
    echo "/backup must be a different volume with enough disk space!"
    umount /snapshot;
    exit 1;
fi;

d=`date +"%Y_%m_%d-%H_%M_%S"`
backup_name="/backup/${snapshot_volume_name}-${d}.tar.gz"
cd /snapshot
tar -cpzvf "$backup_name" *
sha256sum "$backup_name" > "${backup_name}.sha256sum"

cd -
umount /snapshot

echo "about to execute: lvremove \"$snapshot_volume_path\""
echo "Type YES followed by ENTER to confirm."
read confirm
if [ "$confirm" = "YES" ]; then
    lvremove "$snapshot_volume_path";
else
    echo "snapshot volume: $snapshot_volume_path not removed!";
fi;
