#!/bin/bash
set -e

ROOTDIR="/home/user/.wine/drive_c/Fallout"
MODDIR="$ROOTDIR/mods"

FONVDIR="$ROOTDIR/Fallout New Vegas_clean"
MERGERDIR="$ROOTDIR/Fallout New Vegas"
MODDATADIR="$MODDIR/data"
OVFSWORKDIR="$MODDIR/_work"
OVFSOVERLAYDIR="$MODDIR/_overlay"

BASEORDER=$(cat <<'EOF'
FalloutNV.esm
DeadMoney.esm
HonestHearts.esm
OldWorldBlues.esm
LonesomeRoad.esm
GunRunnersArsenal.esm
Fallout3.esm
Anchorage.esm
ThePitt.esm
BrokenSteel.esm
PointLookout.esm
Zeta.esm
CaravanPack.esm
ClassicPack.esm
MercenaryPack.esm
TribalPack.esm
TaleOfTwoWastelands.esm
YUPTTW.esm
EOF
)

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

# find base game ESPs and ESMs, remove duplicates keepeing last occurence
GAMEORDER=$(find "$FONVDIR/Data" -mindepth 3 -maxdepth 3 -type f \( -name '*.esp' -or -name '*.esm' \) -print0 | sort -z | xargs -r0 -n1 basename | awk '!seen[$0]++' | tac)
# find mod ESPs and ESMs, remove duplicates keepeing last occurence
MODORDER=$(find "$MODDATADIR" -mindepth 3 -maxdepth 3 -type f \( -name '*.esp' -or -name '*.esm' \) -print0 | sort -z | xargs -r0 -n1 basename | awk '!seen[$0]++' | tac)

# remove files with predefined order
MODORDER=$(grep -Fxvf <(echo "$BASEORDER") <(echo "$MODORDER"))
# concatenate base and mod lists and reverse result to keep it in same logical
# order that mod overlays are using
MODORDER=$(echo -e "$BASEORDER\n$MODORDER" | tac)

echo "Mounting $MERGERDIR"
echo "If requested, enter password for sudo to mount overlaysfs"

mkdir -p "$OVFSOVERLAYDIR" "$OVFSWORKDIR"

# mount overlay and start unmounter
WAITFORPID=$BASHPID
sudo -k -- /bin/sh <<EOF
# mount overlay
mount -t overlay overlay -o lowerdir="$LOWERDIRS:$FONVDIR",upperdir="$OVFSOVERLAYDIR",workdir="$OVFSWORKDIR",metacopy=on "$MERGERDIR" || {
    echo "Overlay mounting failed"
    exit 1
}
# start watcher to unmount when main process dies
sh -c "echo 'Waiting for $WAITFORPID before unmounting'; tail --pid=$WAITFORPID -f /dev/null; sleep 5; echo 'Unmounting $MERGERDIR'; exec umount -l '$MERGERDIR'" &
EOF

# change file times to enforce load order - the newer file is, the higher
# is its priority
MODCOUNT=$(echo -n "$MODORDER" | grep -c '^')
idx=1
while read -r line; do
    touch -d "$idx days ago" "$MERGERDIR/Data/$line"
    (( idx++ ))
done < <(echo "$MODORDER")

# save mod load order into text file to allow symlinking to it
find "$MERGERDIR"/Data -mindepth 1 -maxdepth 1 -type f \( -name '*.esm' -o -name '*.esp' \) -printf '%Ts\t%p\n' | sort -n | cut -f2 | xargs -n1 -d '\n' basename > "$MERGERDIR"/Data/loadorder.txt

echo "Mod load order is:"
cat "$MERGERDIR"/Data/loadorder.txt
echo

echo "Possible mixed-case file conflicts:"
find "$MERGERDIR" | perl -ne 's!([^/]+)$!lc $1!e; print if 1 == $seen{$_}++'
echo

exec env ROOTDIR="$ROOTDIR" FONVDIR="$MERGERDIR" "$@"
