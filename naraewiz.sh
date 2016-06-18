#!/bin/bash
# Automated NaraeWiz ROM maker for G930K

if [[ ! -e $1/build.prop ]] || [[ "$1" == "" ]]; then
	echo "$(tput setaf 1)$(tput bold)Input correct /system directory path.$(tput sgr0)"
	exit 1
fi
if [ -e $1/framework/oat ]; then
	echo "$(tput setaf 1)$(tput bold)ROM is not properly deodex'ed!$(tput sgr0)"
	exit 1
fi

SYSDIR=$1 # system dir
NWPDIR=_Prebuilt # naraewiz prebuilt dir
NWDEL=del.txt
ECHOINFO() {
	echo "$(tput bold) ::: $@ :::$(tput sgr0)"
}

ABORT() {
	echo "$(tput setaf 1)$(tput bold) !!! ERROR !!!$(tput sgr0)"
	exit 1
}

read -p "$(tput bold)Make sure you entered the right directory path and press Enter to continue.$(tput sgr0)"

cd $SYSDIR
ECHOINFO "Removing Knox"
cat $(NWDEL) | while read file; do
	rm -rf $file
done
#
# DE-KNOX
#

#rm -rf *app/BBCAgent*
#rm -rf *app/Bridge*
#rm -rf *app/ContainerAgent*
#rm -rf *app/ContainerEventsRelayManager*
#rm -rf *app/kioskdefault*
#rm -rf *app/KLMSAgent*
#rm -rf *app/Knox*
#rm -rf *app/KNOX*
#rm -rf *app/RCPComponents*
#rm -rf *app/SwitchKnoxI*
#rm -rf *app/UniversalMDMClient*
#rm -rf *app/SecurityLogAgent*
#rm -rf *app/FotaAgent*
#rm -rf container*
#rm -rf etc/secure_storage/com.sec.knox*
#rm -rf preloadedkiosk*
#rm -rf preloadedsso*
#rm -rf preloadedmdm*
echo "Possible leftovers :"
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
# Fix sdcard RW
#
ECHOINFO "Fixing media storage RW permission"
echo '--- a/etc/permissions/platform.xml       2016-06-11 14:09:42.941502800 +0900
+++ b/etc/permissions/platform.xml        2016-06-05 23:52:09.454970100 +0900
@@ -65,6 +65,7 @@
     <permission name="android.permission.WRITE_MEDIA_STORAGE" >
         <group gid="media_rw" />
         <group gid="sdcard_rw" />
+        <group gid="sdcard_all" />
     </permission>

     <permission name="android.permission.ACCESS_MTP" >' | patch -p1 --forward
rm etc/permissions/platform.xml.* 2>/dev/null

#
# Replace bootanimation
#
ECHOINFO "Replacing bootanimation"
[ ! -e bin/bootanimation.bak ] && mv bin/bootanimation bin/bootanimation.bak
rm media/boot*.qmg* 2>/dev/null
rm media/crypt_boot*.qmg* 2>/dev/null
rm media/shutdown.qmg* 2>/dev/null
cp -R $NWPDIR/bootanim/* ./

#
# Update floating_feature.xml for Edge feature support
#
ECHOINFO "Updating floating_feature.xml for Edge feature support"
echo '--- a/etc/floating_feature.xml   2016-06-05 23:11:44.873739200 +0900
+++ b/etc/floating_feature.xml    2016-06-05 23:52:03.224265700 +0900
@@ -22,7 +22,7 @@
     <SEC_FLOATING_FEATURE_COMMON_CONFIG_ALTER_MODEL_NAME></SEC_FLOATING_FEATURE_COMMON_CONFIG_ALTER_MODEL_NAME>
     <SEC_FLOATING_FEATURE_COMMON_CONFIG_CHANGEABLE_UI></SEC_FLOATING_FEATURE_COMMON_CONFIG_CHANGEABLE_UI>
     <SEC_FLOATING_FEATURE_COMMON_CONFIG_CROSSAPP></SEC_FLOATING_FEATURE_COMMON_CONFIG_CROSSAPP>
-    <SEC_FLOATING_FEATURE_COMMON_CONFIG_EDGE></SEC_FLOATING_FEATURE_COMMON_CONFIG_EDGE>
+    <SEC_FLOATING_FEATURE_COMMON_CONFIG_EDGE>people,task,circle,panel,-nightclock</SEC_FLOATING_FEATURE_COMMON_CONFIG_EDGE>
     <SEC_FLOATING_FEATURE_COMMON_CONFIG_EDGE_STRIPE>-1</SEC_FLOATING_FEATURE_COMMON_CONFIG_EDGE_STRIPE>
     <SEC_FLOATING_FEATURE_COMMON_CONFIG_FESTIVAL_EFFECT_VERSION>2</SEC_FLOATING_FEATURE_COMMON_CONFIG_FESTIVAL_EFFECT_VERSION>
     <SEC_FLOATING_FEATURE_COMMON_CONFIG_HIDE_STATUS_BAR>LAND</SEC_FLOATING_FEATURE_COMMON_CONFIG_HIDE_STATUS_BAR>
@@ -63,7 +63,7 @@
     <SEC_FLOATING_FEATURE_FMRADIO_REMOVE_AF_MENU>FALSE</SEC_FLOATING_FEATURE_FMRADIO_REMOVE_AF_MENU>
     <SEC_FLOATING_FEATURE_FMRADIO_SUPPORT_HYBRID_RADIO>FALSE</SEC_FLOATING_FEATURE_FMRADIO_SUPPORT_HYBRID_RADIO>
     <SEC_FLOATING_FEATURE_FMRADIO_SUPPORT_RDS>TRUE</SEC_FLOATING_FEATURE_FMRADIO_SUPPORT_RDS>
-    <SEC_FLOATING_FEATURE_FRAMEWORK_CONFIG_TASK_EDGE_EMBEDDED_ITEM></SEC_FLOATING_FEATURE_FRAMEWORK_CONFIG_TASK_EDGE_EMBEDDED_ITEM>
+    <SEC_FLOATING_FEATURE_FRAMEWORK_CONFIG_TASK_EDGE_EMBEDDED_ITEM>panorama</SEC_FLOATING_FEATURE_FRAMEWORK_CONFIG_TASK_EDGE_EMBEDDED_ITEM>
     <SEC_FLOATING_FEATURE_FRAMEWORK_SUPPORT_CUSTOM_STARTING_WINDOW>TRUE</SEC_FLOATING_FEATURE_FRAMEWORK_SUPPORT_CUSTOM_STARTING_WINDOW>
     <SEC_FLOATING_FEATURE_FRAMEWORK_SUPPORT_SMOOTH_SCROLL>TRUE</SEC_FLOATING_FEATURE_FRAMEWORK_SUPPORT_SMOOTH_SCROLL>
     <SEC_FLOATING_FEATURE_GALLERY_SUPPORT_EVENTSHARE>TRUE</SEC_FLOATING_FEATURE_GALLERY_SUPPORT_EVENTSHARE>
@@ -100,7 +100,7 @@
     <SEC_FLOATING_FEATURE_MESSAGE_SUPPORT_REGISTER_TO_SPLANNER>FALSE</SEC_FLOATING_FEATURE_MESSAGE_SUPPORT_REGISTER_TO_SPLANNER>
     <SEC_FLOATING_FEATURE_MESSAGE_SUPPORT_SCHEDULED_MESSAGES>FALSE</SEC_FLOATING_FEATURE_MESSAGE_SUPPORT_SCHEDULED_MESSAGES>
     <SEC_FLOATING_FEATURE_MESSAGE_SUPPORT_SELECTION_MODE>TRUE</SEC_FLOATING_FEATURE_MESSAGE_SUPPORT_SELECTION_MODE>
-    <SEC_FLOATING_FEATURE_MESSAGE_SUPPORT_SPLIT_MODE>FALSE</SEC_FLOATING_FEATURE_MESSAGE_SUPPORT_SPLIT_MODE>
+    <SEC_FLOATING_FEATURE_MESSAGE_SUPPORT_SPLIT_MODE>TRUE</SEC_FLOATING_FEATURE_MESSAGE_SUPPORT_SPLIT_MODE>
     <SEC_FLOATING_FEATURE_MESSAGE_SUPPORT_UNKNOWN_URL_LINK>FALSE</SEC_FLOATING_FEATURE_MESSAGE_SUPPORT_UNKNOWN_URL_LINK>
     <SEC_FLOATING_FEATURE_MMFW_SUPPORT_MUSIC_ALBUMART_3DAUDIO>TRUE</SEC_FLOATING_FEATURE_MMFW_SUPPORT_MUSIC_ALBUMART_3DAUDIO>
     <SEC_FLOATING_FEATURE_MMFW_SUPPORT_MUSIC_AUTO_RECOMMENDATION>TRUE</SEC_FLOATING_FEATURE_MMFW_SUPPORT_MUSIC_AUTO_RECOMMENDATION>' | patch -p1 --forward
rm etc/floating_feature.xml.* 2>/dev/null

#
# Import prebuilts
#
ECHOINFO "Importing prebuilt stuff"
ls -d $NWPDIR/*/ | while read i; do cp -R $i/* ./; done

#
# Optimize framework
#
#ECHOINFO "Optimizing framework files"
#find . -type f -name '*.jar' -maxdepth 1 | while read i; do 7z x $i -otest &>NUL; cd test; jar -cf0M $i *; zipalign -f 4 $i ../$i; cd ..; rm -r test; done
#find . -type f -name '*.apk' -maxdepth 1 | while read i; do 7z x $i -otest &>NUL; cd test; 7z a -tzip $i * -mx0 &>NUL; zipalign -f 4 $i ../$i; cd ..; rm -r test; done

ECHOINFO "DONE."
