#!/bin/sh

svnrepos="/path/to/svn"
bakdest="/opt/backups/svn"

echo "Going to backup all SVN repos located at: $svnrepos \n"

# First go to SVN repo folder
cd $svnrepos

# Just make sure we have write access to backup-folder
if [ -d "$bakdest" ] && [ -w "$bakdest" ] ; then
  # Now $repo has folder names = project names
  for repo in *; do
    # do svn dump for each project
    echo "Taking backup/svndump for: $repo"
    echo "Executing : svnadmin dump -q $repo | gzip - > $bakdest/$repo.dump.gz \n"
    # Now finally execute the backup
    
    svnadmin dump -q $repo | gzip - > $bakdest/$repo.dump.gz

  done
else
  echo "Unable to continue SVN backup process."
  echo "$bakdest is *NOT* a directory or you do not have write permission."
  exit 1
fi


