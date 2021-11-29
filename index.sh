#!/bin/bash

function archivedump() {
  echo "This is assuming ur files structure is as current, foldername is html. WORKINGDIR[html] => composer.json => web"
  echo "The script is slow since it doesn't exclude anything! You should consider to wait for the real drush archive-dump ready in version 9!"
  read -r -p "Are you sure? " response
  drush sql-dump >./sql.sql
  tar -czf /tmp/html.tar.gz ../html
  rm ./sql.sql
  local targetdir
  targetdir="$HOME/drush-backups/archive-dump/$(date +%Y%m%d%s)"
  mkdir -p "$targetdir"
  mv /tmp/html.tar.gz $targetdir
  echo "Archive saved to $targetdir/html.tar.gz"
}

function archiverestore() {
  local file
  local copy
  file="$2"
  copy="$3"
  [ ! -f $file ] && echo "File is not available" && return 1
  echo "About to restore entire website from $file"
  echo "This is assuming ur files structure is as current: WORKINGDIR => [TARGETDIR:html] => composer.json => web"
  echo "Ensure you have rights to edit the TARGETDIR"
  read -r -p "Are you sure? Backup yet?" response
  local backupdir
  backupdir="html.$(date +%Y%m%d%s)"
  local targetdir
  targetdir="$PWD"

  [ "$copy" == "" ] && {
    mv html $backupdir || {
      echo "Please check file permission. Use --restore FILEID --copy to not moving folder"
      exit 1
    }
  }

  [ "$copy" != "" ] && {
    cd /tmp
    rm -rf html
  }
  mv $file ./

  tar -xzf $(basename $file)
  mv $(basename $file) $file
  [ "$copy" != "" ] && {
    rsync -raz html/ $targetdir/html
  }

  cd $targetdir/html
  drush sql-cli <./sql.sql
  rm -rf $backupdir

  drush cache-rebuild
  echo "Restored successfully!"
}

[ "$1" == "" ] && archivedump
[ "$1" == "--restore" ] && archiverestore "$@"
