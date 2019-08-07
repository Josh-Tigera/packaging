#!/bin/bash -ex

REPO_NAME=${REPO_NAME:-master}
test -n "$SECRET_KEY"

keydir=`mktemp -t -d calico-publish-debs.XXXXXX`
cp -a $SECRET_KEY ${keydir}/key

docker run --rm -v `pwd`:/code -v ${keydir}:/keydir calico-build/bionic /bin/sh -c "gpg --import < /keydir/key && debsign -kCalico *_*_source.changes"
for series in trusty xenial bionic; do
    # Use the Distribution header to map changes files to Ubuntu versions, as some of our
    # packages don't include the Ubuntu version name in the changes file name.
    for changes_file in `grep -l "Distribution: ${series}" *_source.changes`; do
	docker run --rm -v `pwd`:/code -w /code calico-build/${series} dput -u ppa:project-calico/${REPO_NAME} ${changes_file}
    done
done