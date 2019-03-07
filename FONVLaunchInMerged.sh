#!/bin/bash
set -e

# Customize following variables to match your preferred directory structure

ROOTDIR="/home/user/.wine/drive_c/Fallout"
MODDIR="$ROOTDIR/mods"

MERGERDIR="$ROOTDIR/Fallout New Vegas"
MODDATADIR="$MODDIR/data"
OVFSWORKDIR="$MODDIR/_work"
OVFSOVERLAYDIR="$MODDIR/_overlay"

# Everything below should not be touched

if [ "$#" -eq 0 ]; then
	programname=`basename "$0"`
	echo "ERROR: No program supplied"
	echo
	echo "Usage: $programname <program-to-run>"
	exit 1
fi

LOWERDIRS=`find "$MODDATADIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z | tr '\0' ':' | sed 's/:$//'`

echo "Overlay stacking will be (highest to lowest priority):"
echo "$(echo $LOWERDIRS | tr ':' '\n')"

echo "Mounting $MERGERDIR"
echo "If requested, enter password for sudo to mount overlaysfs"

mkdir -p "$OVFSOVERLAYDIR" "$OVFSWORKDIR"

# mount overlay and start unmounter
WAITFORPID=$BASHPID
sudo -k -- /bin/sh <<EOF
# mount overlay
mount -t overlay overlay -o lowerdir='$LOWERDIRS',upperdir='$OVFSOVERLAYDIR',workdir='$OVFSWORKDIR',metacopy=on '$MERGERDIR' || {
    echo "Overlay mounting failed"
    exit 1
}
# start watcher to unmount when main process dies
sh -c "echo 'Waiting for $WAITFORPID before unmounting'; tail --pid=$WAITFORPID -f /dev/null; sleep 5; echo 'Unmounting $MERGERDIR'; exec umount -l '$MERGERDIR'" &
EOF

GAMEDATADIR="$(find "$MERGERDIR" -maxdepth 1 -mindepth 1 -iname data -print -quit)"

LOADORDERFILE="$GAMEDATADIR/loadorder.txt"
touch "$LOADORDERFILE"
# build mod load order; first (as in OverlayFS order) encountered file is kept
find "$MODDATADIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z | while IFS= read -r -d '' moddir; do
    if [ -f "$moddir.order" ]; then
        tac "$moddir.order"
    else
        find "$moddir" -mindepth 2 -maxdepth 2 -type f \( -name '*.esp' -or -name '*.esm' \) -print0 | sort -zr | xargs -r0 -n1 basename
    fi
done | awk '!seen[$0]++' | tac > "$LOADORDERFILE"

# change file times to enforce load order - the newer file is, the higher
# is its priority
idx=1
while IFS= read -r line; do
    touch -d "1999-12-31 00:00:00Z +$idx days" "$GAMEDATADIR/$line"
    (( idx++ ))
done < <(cat "$LOADORDERFILE")

echo "Mod load order is:"
cat $GAMEDATADIR/loadorder.txt
echo

echo "Possible mixed-case file conflicts:"
find "$MERGERDIR" | perl -ne 's!([^/]+)$!lc $1!e; print if 1 == $seen{$_}++'
echo

exec env ROOTDIR="$ROOTDIR" FONVDIR="$MERGERDIR" "$@"
