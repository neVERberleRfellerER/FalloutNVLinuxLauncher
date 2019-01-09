# Example usage

## Variables

FONVDIR - directory with game (originally created for FONV, hence the name). Nothing will be modified in this directory.

BASEORDER - fixed order of ESM/ESPs at beginning of load order - these will be prepended and order determined by directory scan will be ignored for these. Useful for TTW which contains many files and they have to be interleaved with base game files.

MODDATADIR - directory that contains mod structured as described in "Directory structure". Nothing will be changed in this directory.

MERGERDIR - directory where merged filesystem will be mounted

OVFSWORKDIR - what OverlayFS calls work dir; not important, just point it to writable location

OVFSOVERLAYDIR - what OverlayFS calls overlay dir; not important, just point it to writable location

All changes (including creation and deletion of files) are handled by OverlayFS so even UIO is perfectly safe to use - it will not change anything in MODDATADIR or FONVDIR.

## Directory structure

Scripts expects clean game directory (tested with Fallout NV) in FONVDIR, mods in MODDATADIR and writable directory in MODDIR where OverlayFS files will be stored.

MODDATADIR should contain directories that after ascending ASCII alphabetical ordering matches mod load order where first directories have highest priority and latest lowest priority. Example:

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
$MODDATADIR/9998 TTW321
$MODDATADIR/9999 TTW32
```

These directories are merged directly to game root folder so put your mods into Data subdirectory, e.g.:
`$MODDATADIR/0005 UIO/Data`
`$MODDATADIR/9998 TTW321/Data`
This is to allow overwriting/merging of DLL files, for example:
`$MODDATADIR/0002 native dlls/d3dx9_38.dll`
and similar.

You can pick whatever ordering you want, but number prefixing is commonly used in world of UNIX-like systems for config ordering.

The resulting mod load order is such that TTW have lovest priority and libvorbis (dll files) highest, effectively overwriting files with same names from TTW.

To have deterministic load order make sure that each directory contains only one ESP or ESM (unless order is specified explicitly in BASEORDER variable).

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
