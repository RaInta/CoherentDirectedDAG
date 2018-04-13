#!/bin/bash

# local perl home
HERE=$(pwd -P)


############################################################
#####  Uncomment below if you need perl 5.10.1   ###########
############################################################
## install perl 5.10.1
#if [ ! -x $HERE/perl-5.10.1 ]; then
#    wget http://www.cpan.org/src/5.0/perl-5.10.1.tar.gz
#    tar -xzf perl-5.10.1.tar.gz
#fi
#
#if [ ! -x ${HERE}/bin/perl ]; then
#    cd perl-5.10.1/
#    ./Configure -des -Dprefix=$HERE
#    make
#    make install
#    cd ..
#    export PATH="${HERE}/bin:${PATH}"
#    echo -n "export " >>${HOME}/.bash_profile
#    env | grep ^PATH= >>${HOME}/.bash_profile
#fi
############################################################



# install local::lib
if [ ! -x local-lib-2.000012 ]; then
    curl -L http://search.cpan.org/CPAN/authors/id/H/HA/HAARG/local-lib-2.000012.tar.gz | tar xz
    cd local-lib-2.000012
    perl Makefile.PL --bootstrap
    make install
    cd ..
    eval $(perl -I${HOME}/perl5/lib/perl5 -Mlocal::lib)
    echo 'eval $(perl -I${HOME}/perl5/lib/perl5 -Mlocal::lib)' >> ${HOME}/.bash_profile
fi

# install cpanm
if [ ! -x ${HOME}/perl5/bin/cpanm ]; then
    curl -L http://cpanmin.us | ${HERE}/bin/perl - --local-lib=${HOME}/perl5 --notest --self-upgrade --reinstall --force
fi

# install needed modules
${HOME}/perl5/bin/cpanm --local-lib=${HOME}/perl5 --notest --reinstall --force XML::Simple XML::Twig IO::Compress::Bzip2 IO::Uncompress::Bunzip2

source ${HOME}/.bash_profile
