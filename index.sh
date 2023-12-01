#!/bin/bash

function archivedump() {
  local fd
  fd=$(pwd | rev | cut -d "/" -f 1 | rev)
  echo "This is assuming ur files structure [${fd}: current} => composer.json"
  echo "The script is slow since it doesn't exclude anything! You should consider to wait for the real drush archive-dump ready in version 9!"
  read -r -p "Are you sure? " response
  drush sql-dump --extra=-f >./sql.sql
  local tmpdir
  tmpdir="$HOME/drush-backups/tmp"
  mkdir -p $tmpdir
  tar -czf ${tmpdir}/${fd}.tar.gz ../${fd}
  rm ./sql.sql
  local targetdir
  targetdir="$HOME/drush-backups/archive-dump/$(date +%Y%m%d%s)"
  mkdir -p "$targetdir"
  mv ${tmpdir}/${fd}.tar.gz $targetdir
  echo "Archive saved to $targetdir/${fd}.tar.gz"
}

function archiverestore() {
  local file
  local copy
  local fd
  file="$2"
  copy="$3"
  fd=$(echo ${file} | rev | cut -d "/" -f 1 | rev | cut -d "." -f 1)
  [ ! -f $file ] && echo "File $file is not available" && return 1
  [ "" == "$file" ] && echo "File $file is not available" && return 1
  echo "About to restore entire website from $file"
  echo "This is assuming ur files structure is as current: [WORKING/TARGETDIR:${fd}] => composer.json"
  [ ! -d ../${fd} ] && echo "[CAUTION] Dir $fd is not available"
  echo "Ensure you have rights to edit the TARGETDIR ../${fd}"
  read -r -p "Are you sure? Backup yet?" response
  local backupdir
  backupdir="${fd}.$(date +%Y%m%d%s)"
  local targetdir
  targetdir="$PWD"

  [ "$copy" == "" ] && {
    mv ${fd} $backupdir || {
      echo "Please check file permission. Use --restore FILEID --copy to not moving folder"
      exit 1
    }
  }

  [ "$copy" != "" ] && {
    local tmpdir
    tmpdir="$HOME/drush-backups/tmp"
    mkdir -p $tmpdir
    rm -rf ${tmpdir}/${fd}
  }
  mv $file ./

  tar -xzf $(basename $file)
  mv $(basename $file) $file
  [ "$copy" != "" ] && {
    rsync -raz ${fd}/ $targetdir/${fd}
  }

  cd $targetdir/${fd}
  drush sql-cli <./sql.sql
  rm -rf $backupdir

  drush cache-rebuild
  echo "Restored successfully!"
}

[ "$1" == "" ] && archivedump
[ "$1" == "--restore" ] && archiverestore "$@"
