# Simple instructions

Simple instructions written by remyabel are available here:
https://linuxguideandhints.com/fedora/winetips.html#id2

More detailed and more technical but also more confusing guide is below.

# Example usage

## Variables

MODDATADIR - directory that contains mod structured as described in "Directory structure". Nothing will be changed in this directory. Base game is also treated as mod and should be last in order.

MERGERDIR - directory where merged filesystem will be mounted

OVFSWORKDIR - what OverlayFS calls work dir; not important, just point it to writable location

OVFSOVERLAYDIR - what OverlayFS calls overlay dir; not important, just point it to writable location

All changes (including creation and deletion of files) are handled by OverlayFS so even UIO is perfectly safe to use - it will not change anything in MODDATADIR or FONVDIR.

## Directory structure

Script expects mods and base game in MODDATADIR and writable directory in OVFSWORKDIR and OVFSOVERLAYDIR where OverlayFS files will be stored.

MODDATADIR should contain directories that after ascending ASCII alphabetical ordering matches mod load order where first directories have highest priority and latest lowest priority. manual ordering is possible by file named after directory they belong to with ".order" appended. To exclude directory from scan, create empty order file. Example:

```
$MODDATADIR/0001 libvorbis
$MODDATADIR/0002 native dlls
$MODDATADIR/0004 enb
$MODDATADIR/0005 UIO
$MODDATADIR/0010 JIP LN NVSE
$MODDATADIR/0495 Vanilla UI Plus
$MODDATADIR/9500 BLEED
$MODDATADIR/9800 JIP CCC
$MODDATADIR/9850 MCM
$MODDATADIR/9997 TTW321
$MODDATADIR/9997 TTW321.order
$MODDATADIR/9998 TTW32
$MODDATADIR/9998 TTW32.order
$MODDATADIR/9999 Fallout New Vegas
$MODDATADIR/9999 Fallout New Vegas.order
```

Since these directories are just merged over each other, put your mods into Data subdirectory, e.g.:
`$MODDATADIR/0005 UIO/Data`
`$MODDATADIR/9998 TTW321/Data`
This is to allow overwriting/merging of DLL files, for example:
`$MODDATADIR/0002 native dlls/d3dx9_38.dll`
and similar. It also makes possible to treat game as mod which simplifies script and makes case-sensitive conflict checking more robust.

You can pick whatever ordering you want, but number prefixing is commonly used in world of UNIX-like systems for config ordering.

The resulting mod load order is such that TTW have lovest priority and libvorbis (dll files) highest, effectively overwriting files with same names from TTW. Order files are inserteted instead of files present in matching directories.

To have deterministic load order make sure that each directory contains only one ESP/ESM or that order is specified in order file.

### Example of order files for Fallout New vegas + Tale of Two Wastelands 3.2.1:

9999 Fallout New Vegas.order:
```
FalloutNV.esm
DeadMoney.esm
HonestHearts.esm
OldWorldBlues.esm
LonesomeRoad.esm
GunRunnersArsenal.esm
Fallout3.esm
CaravanPack.esm
ClassicPack.esm
MercenaryPack.esm
TribalPack.esm
```
This one could be also empty or even nonexistent in this case because all files are overwriten by `9998 TTW32.order`. But having it allows simple removal of TTW if desired.

9998 TTW32.order:
```
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
```

Since TTW 3.2.1 patch does not add new mod files but contains updated files, it is necessary to create empty order file for it (`9997 TTW321.order`) to preserve order specified in `9998 TTW32.order`, otherwise priority of files from `9997 TTW321` would be pushed to be higher than priority of files in `9998 TTW32`.

## Start

FONVDIR variable is provided by FONVLaunchInMerged so you don't have to hardcode mergedi variable at two places.

```shell
exec env WINEESYNC=1 WINEDLLOVERRIDES="d3d9=n,b" WINE_LARGE_ADDRESS_AWARE=1 ./FONVLaunchInMerged.sh sh -c 'cd "$FONVDIR"; exec wine FalloutNV.exe'
```

or

```shell
exec env WINEESYNC=1 WINEDLLOVERRIDES="d3d9=n,b" WINE_LARGE_ADDRESS_AWARE=1 ./FONVLaunchInMerged.sh sh -c 'cd "$FONVDIR"; exec wine FalloutNVLauncher.exe'
```

Put this to script for easier launching.

Since mod authors use variaous file name casing, script will check MODDATADIR for possible conflicts. Conflicts are echoed after "Possible mixed-case file conflicts:" line and the line is always printed even when no conflicts are present - in this case there will be empty line below the message.

Mod will also create
$MERGERDIR/Data/loadorder.txt
that you can symlink to AppData/Local/FalloutNV/plugins.txt if necessary.

# License

WTFPL
