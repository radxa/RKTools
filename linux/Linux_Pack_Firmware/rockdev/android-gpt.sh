#!/bin/bash -e
#########################################################################
LOADER1_SIZE=8000
UBOOT_SIZE=8192    
TRUST_SIZE=8192    
MISC_SIZE=8192  
RESOURCE_SIZE=32768
KERNEL_SIZE=49152
BOOT_SIZE=65536   
RECOVERY_SIZE=65536
BACKUP_SIZE=229376
CACHE_SIZE=262144
SYSTEM_SIZE=3145728
METADATA_SIZE=32768
BASEPARAMER_SIZE=8192
#########################################################################
SYSTEM_START=0
LOADER1_START=64 							#1
UBOOT_START=16384  							#2
TRUST_START=$(expr ${UBOOT_START} + ${UBOOT_SIZE})			#3
MISC_START=$(expr ${TRUST_START} + ${TRUST_SIZE})			#4
RESOURCE_START=$(expr ${MISC_START} + ${MISC_SIZE})			#5
KERNEL_START=$(expr ${RESOURCE_START} + ${RESOURCE_SIZE})		#6
BOOT_START=$(expr ${KERNEL_START} + ${KERNEL_SIZE})			#7
RECOVERY_START=$(expr ${BOOT_START} + ${BOOT_SIZE})			#8
BACKUP_START=$(expr ${RECOVERY_START} + ${RECOVERY_SIZE})		#9
CACHE_START=$(expr ${BACKUP_START} + ${BACKUP_SIZE})			#10
SYSTEM_START=$(expr ${CACHE_START} + ${CACHE_SIZE})			#11
METADATA_START=$(expr ${SYSTEM_START} + ${SYSTEM_SIZE})			#12
BASEPARAMER_START=$(expr ${METADATA_START} + ${METADATA_SIZE})		#13
USERDATA_START=$(expr ${BASEPARAMER_START} + ${BASEPARAMER_SIZE}) 	#14
#########################################################################

LOCALPATH=$(pwd)
OUT=${LOCALPATH}/Image
#SIMG2IMG=../out/host/linux-x86/bin/simg2img
PATH=../out/host/linux-x86/bin/simg2img:${PATH}

SYSTEM1=${OUT}/gpt.img
if [ -f "${SYSTEM1}" ];then
    rm -rf ${SYSTEM1}
fi

echo "Generate gpt image : ${SYSTEM1} !"

# last dd rootfs will extend gpt image to fit the size,
# but this will overrite the backup table of GPT
# will cause corruption error for GPT

#IMG_USERDATA_SIZE=3870294016   ##$(stat -L --format="%s" ${USERDATA_PATH})
GPTIMG_MIN_SIZE=$(expr \( 16384 + ${UBOOT_SIZE} + ${TRUST_SIZE} + ${MISC_SIZE} + ${RESOURCE_SIZE} + ${KERNEL_SIZE} + ${BOOT_SIZE} + ${RECOVERY_SIZE} + ${BACKUP_SIZE} + ${CACHE_SIZE} + ${SYSTEM_SIZE} + ${METADATA_SIZE} + ${BASEPARAMER_SIZE} + 35 \) \* 512)

echo "GPT_IMAGE_SIZE byte= $GPTIMG_MIN_SIZE Bytes"
GPT_IMAGE_SIZE=$(expr $GPTIMG_MIN_SIZE \/ 1024 \/ 1024 + 2)

echo "GPT_IMAGE_SIZE = $GPT_IMAGE_SIZE MB"

dd if=/dev/zero of=${SYSTEM1} bs=1M count=0 seek=$GPT_IMAGE_SIZE

parted -s ${SYSTEM1} mklabel gpt
echo "name        start	               end"
echo "loader1     ${LOADER1_START}     $(expr ${UBOOT_START} - 1)"
echo "uboot       ${UBOOT_START}       $(expr ${TRUST_START} - 1)"
echo "trust       ${TRUST_START}       $(expr ${MISC_START} - 1)"
echo "misc        ${MISC_START}        $(expr ${RESOURCE_START} - 1)"
echo "resource    ${RESOURCE_START}    $(expr ${KERNEL_START} - 1)"
echo "kernel      ${KERNEL_START}      $(expr ${BOOT_START} - 1)"
echo "boot        ${BOOT_START}        $(expr ${RECOVERY_START} - 1)"
echo "recovery    ${RECOVERY_START}    $(expr ${BACKUP_START} - 1)"
echo "backup      ${BACKUP_START}      $(expr ${CACHE_START} - 1)"
echo "cache       ${CACHE_START}       $(expr ${SYSTEM_START} - 1)"
echo "system      ${SYSTEM_START}      $(expr ${METADATA_START} - 1)"
echo "metadata    ${METADATA_START}    $(expr ${BASEPARAMER_START} - 1)"
echo "baseparamer ${BASEPARAMER_START} $(expr ${USERDATA_START} - 1)"
echo "userdata    ${USERDATA_START}    ..."

parted -s ${SYSTEM1} unit s mkpart loader1 ${LOADER1_START} $(expr ${UBOOT_START} - 1)
parted -s ${SYSTEM1} unit s mkpart uboot ${UBOOT_START} $(expr ${TRUST_START} - 1)     ##16384 24575
parted -s ${SYSTEM1} unit s mkpart trust ${TRUST_START} $(expr ${MISC_START} - 1)  ##24576 32767
parted -s ${SYSTEM1} unit s mkpart misc ${MISC_START} $(expr ${RESOURCE_START} - 1) ##32768 40959
parted -s ${SYSTEM1} unit s mkpart resource ${RESOURCE_START} $(expr ${KERNEL_START} - 1) ##32768 40959
parted -s ${SYSTEM1} unit s mkpart kernel ${KERNEL_START} $(expr ${BOOT_START} - 1) ##32768 40959
parted -s ${SYSTEM1} unit s mkpart boot ${BOOT_START} $(expr ${RECOVERY_START} - 1)  ##40960 106495
parted -s ${SYSTEM1} unit s mkpart recovery ${RECOVERY_START} $(expr ${BACKUP_START} - 1)   ## 106496 172031
parted -s ${SYSTEM1} unit s mkpart backup ${BACKUP_START} $(expr ${CACHE_START} - 1)  ##237567
parted -s ${SYSTEM1} unit s mkpart cache ${CACHE_START} $(expr ${SYSTEM_START} - 1)  ##237567
parted -s ${SYSTEM1} unit s mkpart system ${SYSTEM_START} $(expr ${METADATA_START} - 1)  ##237567
parted -s ${SYSTEM1} unit s mkpart metadata ${METADATA_START} $(expr ${BASEPARAMER_START} - 1)  ##237567
parted -s ${SYSTEM1} unit s mkpart baseparamer ${BASEPARAMER_START} $(expr ${USERDATA_START} - 1)  ##237567
parted -s ${SYSTEM1} set 13 boot on
parted -s ${SYSTEM1} -- unit s mkpart userdata ${USERDATA_START}  -34s

#burn uboot image
dd if=${OUT}/idbloader.img of=${SYSTEM1} seek=${LOADER1_START} conv=notrunc
 
#burn uboot image
dd if=${OUT}/uboot.img of=${SYSTEM1} conv=notrunc seek=${UBOOT_START}

#burn trust image
dd if=${OUT}/trust.img of=${SYSTEM1} conv=notrunc seek=${TRUST_START}

#burn misc image
dd if=${OUT}/misc.img of=${SYSTEM1} conv=notrunc seek=${MISC_START}

#burn resource image
dd if=${OUT}/resource.img of=${SYSTEM1} conv=notrunc seek=${RESOURCE_START}

#burn kernel image
dd if=${OUT}/kernel.img of=${SYSTEM1} conv=notrunc seek=${KERNEL_START}

# burn boot image
dd if=${OUT}/boot.img of=${SYSTEM1} conv=notrunc seek=${BOOT_START}

# burn recovery image 
dd if=${OUT}/recovery.img of=${SYSTEM1} conv=notrunc seek=${RECOVERY_START}

# burn oem image 
#dd if=${OUT}/oem.img of=${SYSTEM} conv=notrunc seek=${OEM_START}

#burn userdata image                                                                                               
#dd if=${OUT}/userdata.img of=${SYSTEM} conv=notrunc seek=${USERDATA_START}

# burn system image
if (file ${OUT}/system.img | grep -q "Android sparse image");then
    echo "simg2img system.img"
    simg2img ${OUT}/system.img ${OUT}/system.unsimg.img
    dd if=${OUT}/system.unsimg.img of=${SYSTEM1} conv=notrunc seek=${SYSTEM_START}
else
    dd if=${OUT}/system.img of=${SYSTEM1} conv=notrunc seek=${SYSTEM_START}
fi
