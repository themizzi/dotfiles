if test $(which rpm); then
    if test $(rpm -qa \*-release | grep -Ei "centos" | cut -d"-" -f3) -eq "6"; then
        sudo yum remove -y git
        sudo yum install -y zlib-devel perl-devel asciidoc xmlto openssl-devel
        wget -O git.zip https://github.com/git/git/archive/master.zip
        unzip git.zip
        cd git-master
        make configure
        ./configure --prefix=/usr/local
        make all doc
        sudo make install install-doc install-html
    fi
fi

if test ! $(which brew); then
    echo "Installing Homebrew for you."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install)"
fi
