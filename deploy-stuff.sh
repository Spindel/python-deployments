et -e
: ${PROJECT:=display}
: ${SUBPROJ:=template}
: ${SERVER:=template.modio.se}

FREEBOARD="$PROJECT/$PROJECT/freeboard/"
TMPDIR=$(mktemp -d /tmp/${SUBPROJ}.XXXXX)
trap "rm -rf $TMPDIR" EXIT

REV=$(git rev-parse --verify --short HEAD)
(git archive HEAD "$PROJECT" | tar -f - -xC "$TMPDIR")
(cd "$FREEBOARD"; git archive HEAD . |tar -f - -xC "$TMPDIR/$FREEBOARD")
(cd "$TMPDIR/$PROJECT"; ln -sf "${SUBPROJ}.ini" production.ini;  python -m unittest discover) || exit

# Upload project first, shared lib later
rsync -vrl "$TMPDIR/$PROJECT/" "$SUBPROJ@$SERVER:/srv/$SERVER/$PROJECT-$REV"
ssh -t "$SUBPROJ@$SERVER" "/srv/$SERVER/$PROJECT-$REV/deploy.sh" "$PROJECT" "$REV" 

## All done
echo "**** All worked.  Python has been restarted for the webserver"

