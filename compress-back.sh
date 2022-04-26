#!/usr/bin/sh

#
# compress using 7z and backup to ...
# compress-backup.sh source-target
#
#pwd=$(cd `dirname $0` || exit; pwd)
SCRIPT_PATH=`dirname $0`
source "${SCRIPT_PATH}/core.sh"

# where to backup
target="/c/myCodes/myjava/0_system_files/backuped-files"
#target="/d/Download/1020"

info "start to backup all important files"
string::repeat "*" 80

# home of current user
home="${HOME}"

# file and dir to be backuped up
files=(
  "$home/.bashrc"
  "$home/.gradle/init.gradle"
  "$home/.m2/settings.xml"
  "/c/Windows/System32/drivers/etc/hosts"
  "/c/mySoft/BakFiles/usefull"
)

for f in ${files[@]};
do
  if [ ! -e $f ]; then
    error "$f not existing"
    continue
  fi

  if [ -f $f ]; then
    thisDir=$(dirname $f)
    thisDir="$target$thisDir"

    thisFile=$(basename $f)
    targetFile="$thisDir/$thisFile"

    info ">>> $f -> $targetFile"
    mkdir -p "$thisDir"
    cp $f $targetFile
  elif [ -d $f ]; then
    # /d/test/1014/
    # handle last "/"
    d=$(dirname $f)
    f=$(basename $f)

    # /d/test/1014
    thisDir="$d/$f"

    targetDir="$target/$thisDir"
    targetDir=${targetDir//\/\//\/}
    # /d/download/1020/d/test
    targetDir=$(dirname $targetDir)
    mkdir -p "$targetDir"

    `cp -r "$thisDir" $targetDir`
    info ">-- $thisDir ->  $targetDir/"
  fi

done

string::repeat "*" 80
showBlue "All files are backed up to $target\n"
