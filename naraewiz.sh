#!/bin/bash
# Automated NaraeWiz ROM maker for G930K

if [ ! -e $1/build.prop ]; then
	echo "$(tput setaf 1)$(tput bold)Input /system directory path.$(tput sgr0)"
	exit 1
fi
if [ -e $1/framework/oat ]; then
	echo "$(tput setaf 1)$(tput bold)ROM is not properly deodex'ed!$(tput sgr0)"
	exit 1
fi

SYSDIR=$1 # system dir
NWDIR=$PWD # script location
PREBUILTDIR=$(realpath _Prebuilt)
PATCHDIR=$(realpath _Patch)
MODDIR=$(realpath _Mod)

if [ -e /mnt/c/Windows ]; then
	IS_LINUX=0
else
	IS_LINUX=1
fi

ECHOINFO() {
	echo ""
	echo "$(tput setaf 6)$(tput bold)    ::: $@ :::$(tput sgr0)"
}

ABORT() {
	echo "$(tput setaf 1)$(tput bold) !!! ERROR !!!$(tput sgr0)"
	exit 1
}

APPLY_PATCH() {
	echo "$(tput bold)Applying patch :$(tput sgr0) $1"
	patch -p1 --forward --merge --no-backup-if-mismatch < $1
	if [ $? -ne 0 ]; then
	while read -p "$(tput setaf 1)$(tput bold)Patch failed, abort? (y/N)$(tput sgr0)" PATCH_CONTINUE; do
		case "$PATCH_CONTINUE" in
		Y | y) exit 1;;
		* ) break;;
		esac
	done
	fi
}

read -p "$(tput bold)Make sure you entered the right directory path and press Enter to continue.$(tput sgr0)"

cd $SYSDIR

#
# NaraeWiz signature
#
sed -i -e 's/buildinfo.sh/buildinfo.sh\n# Powered by NaraeWiz!/g' build.prop

#
# Clean up unnecessary stuff
#
ECHOINFO "Removing spys"
cat $NWDIR/remove.txt | while read file; do
	rm -rf $file
done
echo "Possible knox leftovers :"
find . -iname '*knox*' -exec echo {} \;

#
# Patch build.prop
#
ECHOINFO "Disabling securestorage"
sed -i 's/ro.securestorage.support=.*/ro.securestorage.support=false/' build.prop

#
# Prevent stock recovery restoration
#
ECHOINFO "Preventing stock recovery from being restored"
[ -e recovery-from-boot.p ] && mv recovery-from-boot.p recovery-from-boot.bak

#
# Replace bootanimation binary with that of CM so we can use *.zip instead of annoying *.qmg
#
ECHOINFO "Prepare for new bootanimations"
[ ! -e bin/bootanimation.bak ] && mv bin/bootanimation bin/bootanimation.bak

#
# Apply patches
#
ECHOINFO "Applying patches"
for i in $PATCHDIR/*.patch; do APPLY_PATCH $i; done
for i in $PATCHDIR/*.sh; do $i; done
#find $PATCHDIR -name '*.patch' | while read file; do APPLY_PATCH $file; done
#find $PATCHDIR -name '*.sh' | while read file; do $file; done

#
# Apply patches for MODs
#
ECHOINFO "Modding apk's & jar's"
for WORKDIR in app priv-app framework; do
ls $MODDIR/$WORKDIR | while read i; do
	cd $WORKDIR/$i || cd $WORKDIR 2> /dev/null
	if [ -e $i.apk ]; then
		mkdir -p $SYSDIR/BAK/$WORKDIR/$i
		cp $i.apk $SYSDIR/BAK/$WORKDIR/$i/$i.apk
		apktool d $i.apk -o $i
	elif [ -e $i.jar ]; then
		mkdir -p $SYSDIR/BAK/$WORKDIR
		cp $i.jar $SYSDIR/BAK/$WORKDIR/$i.jar
		apktool d $i.jar -o $i
	else
		ABORT
	fi
	cd $i
	for k in $MODDIR/$WORKDIR/$i/*.patch; do APPLY_PATCH $k; done
	for k in $MODDIR/$WORKDIR/$i/*.sh; do $k; done
	apktool b -c .
	if [ $IS_LINUX -eq 1 ]; then
		zipalign -f 4 dist/$i.apk ../$i.apk || zipalign -f 4 dist/$i.jar ../$i.jar
	else
		cp dist/$i.* ../
	fi
	cd ..
	rm -rf $i
	cd $SYSDIR	
done
done

#
# Import prebuilts
#
ECHOINFO "Importing prebuilts"
ls -d $PREBUILTDIR/*/ | while read file; do cp -R $file/* ./; done

#
# Optimize framework : I need to find a zipalign binary that works on bash on windows first.
# So, only for linux users at the moment.
#
if [ $IS_LINUX -eq 1 ]; then
ECHOINFO "Optimizing framework files"
cd framework
for file in *.jar; do
	7z x $file -otest &> /dev/null
	cd test
	jar -cf0M $file *
	zipalign -f 4 $file ../$file
	cd ..
	rm -r test
done
for file in *.apk; do
	7z x $file -otest &> /dev/null
	cd test
	7z a -tzip $file * -mx0 &> /dev/null
	zipalign -f 4 $file ../$file
	cd ..
	rm -r test
done
fi
cd ..

ECHOINFO "DONE."
