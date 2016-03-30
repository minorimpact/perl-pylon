#!/bin/bash

set -x

while getopts "hn" cliopts
do
    case "$cliopts" in
    h)  echo $USAGE;
        exit 0;;
    n) REPO="norepo";;
    \?) echo $USAGE;
        exit 1;;
    esac
done

LIVE_DIR="/usr/share/perl5/vendor_perl";
LIVE2_DIR="/usr/lib/perl5/vendor_perl";
RELEASE_DIR="/admin/yum-repo/opstools";
BASENAME=$(basename $0)
USAGE="Usage: $(basename $0) [-h] [-n]"
_DIRNAME=$(dirname $0)
if [ -d $_DIRNAME ]; then
    cd $_DIRNAME
    DIRNAME=$PWD
    cd $OLDPWD
fi

NAME=`/bin/grep Name $DIRNAME/*.spec | /bin/cut -d' ' -f2`;
VERSION=`/bin/grep Version $DIRNAME/$NAME.spec | /bin/cut -d' ' -f2`;
RELEASE=`/bin/grep Release $DIRNAME/$NAME.spec | /bin/cut -d' ' -f2`;
if [ "$VERSION" = '' -o "$RELEASE" = '' ];
then
    echo "Cannot determine version or release number."
    exit 1
fi

mkdir -p $HOME/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

PACKAGE_NAME="$NAME-$VERSION"
BUILD_DIR="$HOME/rpmbuild/BUILD"
BASE_DIR="$BUILD_DIR/$PACKAGE_NAME"
ROOT_DIR="$BASE_DIR/$LIVE_DIR"
ROOT2_DIR="$BASE_DIR/$LIVE2_DIR"
SOURCE_DIR="$HOME/rpmbuild/SOURCES"

[ -f $SOURCE_DIR/$PACKAGE_NAME.tar.gz ] && rm -f $SOURCE_DIR/$PACKAGE_NAME.tar.gz
[ -d $ROOT_DIR ] && rm -rf $ROOT_DIR
[ -d $ROOT2_DIR ] && rm -rf $ROOT2_DIR
mkdir -p $ROOT_DIR
mkdir -p $ROOT2_DIR

cp -a $DIRNAME/../* $ROOT_DIR
cp -a $DIRNAME/../* $ROOT2_DIR

cd $BUILD_DIR
tar -c -v -z --exclude='.git' --exclude='build' -f ${PACKAGE_NAME}.tar.gz $PACKAGE_NAME/
cp ${PACKAGE_NAME}.tar.gz $SOURCE_DIR/

rm -rf $BASE_DIR
rpmbuild -ba --define "_binary_filedigest_algorithm  1"  --define "_binary_payload 1" $DIRNAME/$NAME.spec

if [ "$REPO" != "norepo" ];
then
    cd $HOME
    RPM="$PACKAGE_NAME-$RELEASE.noarch.rpm"
    cp rpmbuild/RPMS/noarch/$RPM $RELEASE_DIR/
    createrepo -s sha $RELEASE_DIR
fi

