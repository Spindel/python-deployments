#! /bin/bash
set -e
## get the paths
HERE="$(dirname "$(readlink -f "$0")")"
PROJECT="$1"
REV="$2"
venv=/opt/venv/"$PROJECT-$REV"

# Create new VirtualEnv
scl enable python33 "virtualenv-3.3 $venv"
/sbin/restorecon -vR "$venv"

# Virtual env population & install
scl enable python33 "bash -c \
'source \"${venv}/bin/activate\";\
 cd \"${HERE}\"; python setup.py install;'"

/sbin/restorecon -vR "$venv"


## Set up venv inside web-root
cd "$HERE"/..
rm -f "$PROJECT".ini "$PROJECT"-venv
ln -s "$HERE"/production.ini "$PROJECT".ini
ln -s "$venv" "$PROJECT"-venv
WHAT=$(readlink -f $HERE/..)
pkill -f $WHAT

