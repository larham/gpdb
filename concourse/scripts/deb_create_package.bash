#!/bin/bash
set -euxo pipefail

SRC_DIR=gpdb_src

apt-get update
apt-get install -y software-properties-common \
                   vim \
                   debmake \
                   equivs \
                   git
add-apt-repository -y ppa:ubuntu-toolchain-r/test
apt-get update

pushd ${SRC_DIR}
    VERSION=`./getversion | tr " " "."`
    SHA=`git rev-parse --short HEAD`
    MESSAGE="Bumping to Greenplum version $VERSION, git SHA $SHA"
    PACKAGE=`cat debian/control | egrep "^Package: " | cut -d " " -f 2`

    dch --create -M --package $PACKAGE -v $VERSION "$MESSAGE"
popd

set +e
    # processing triggers can result in a non-zero result code
    yes | mk-build-deps -i ${SRC_DIR}/debian/control
set -e


# todo: since we prefer apt-get instead of pip,
# check if conan authors have released their debian package yet via apt-get: https://www.conan.io/downloads
pip install conan

pushd ${SRC_DIR}
    dpkg-buildpackage -us -uc -b
    # print contents just for human-readable feedback; not necessary
    dpkg --contents ../greenplum-db*.deb
popd
cp greenplum-db*.deb deb_package_ubuntu16/greenplum-db.deb
