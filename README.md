<h1 id="top">🪄🤖<code>magicmake</code></h1>

1. [About](#about)
1. [Usage](#usage)
      1. [Options](#options)
      1. [Examples](#examples)
1. [Rationale](#rationale)
1. [Dependencies](#dependencies)
1. [Installation](#installation)
1. [Demo](#demo)
      1. [https://github.com/petere/pguri.git](#pguri)
      1. [https://github.com/pramsey/pgsql-http.git](#pgsql-http)
1. [Implementation](#implementation)
      1. [/var/lib/apt/lists](#apt-lists)
      1. [update_file_packages.sh](#update-file-packages)
      1. [magicmake.file_packages](#file-packages)
      1. [magicmake command](#magicmake-command)
      1. [magicmake.suggest_packages(trace_files_log text, trace_commands_log text)](#suggest-packages)

<h2 id="about">1. About</h2>

**magicmake**: auto-install missing packages when building from source

![magicmake demo](https://github.com/truthly/demos/blob/master/magicmake.gif "Demo showing magicmake running PostgreSQL's ./configure")

In the example above, PostgreSQL is built from source:

    magicmake ./configure

`magicmake` runs the build command in a loop until, until no more packages to install can be detected.

Finally, it outputs a list of suggested packages and which one the user selected to install or not:

    🪄 🤖 magicmake: no more packages to install ✅
    installed:  bison flex libreadline-dev pkg-config zlib1g-dev libxml2-utils xsltproc
    not installed:  libedit-dev libencode-perl liblog-agent-perl libncurses-dev dbtoepub fop

The next step in the build process is to run `make`, not included in this demo.

<h2 id="usage">2. Usage</h2>

**magicmake** \[**-yqhlc**\] \[*build_command* \[*build_arguments*\]\]

<h3 id="options">Options</h3>

|      |                                                                            |
|----- | -------------------------------------------------------------------------- |
|**-y**| assume **y** (*yes*) as an answer to all prompts and run non-interactively |
|**-q**| run quietly; suppress output from build and package install commands       |
|**-h**| show this help, then exit                                                  |
|**-l**| show list of suggested packages                                            |
|**-c**| clear list of suggested packages                                           |
|**-s**| search packages with file paths matching pattern                           |
|      | a percent sign (%) matches any sequence of zero or more characters         |
|**-F**| search packages containing file_path (fixed string search)                 |

The default *build_command* is **make** with no *build_arguments*.
It can be overriden either by passing argument(s) to magicmake,
or setting the **MAGICMAKE_BUILD_CMD** environment variable.

When a missing package is detected by magicmake,
it will prompt the user asking if the package should be installed.

The default package installation command is **sudo apt install**,
except when using **-y** which changes it to **sudo apt-get -y install**.
To override, set the **MAGICMAKE_INSTALL_CMD** environment variable.

A package will only be suggested by magicmake once,
by remembering what packages have been suggested so far.

If by mistake answering **n** (*no*) when a missing package was suggested,
use **magicmake -c** to clear the list and rerun.

<h3 id="examples">Examples</h3>

Calling `magicmake` with no arguments will invoke `make`:

    magicmake

Which is the same thing as doing:

    magicmake make

To invoke some other *build_command*, pass it as an argument:

    magicmake ./configure

The *build_command* is invoked with all the *build_arguments*:

    magicmake ./configure --prefix=/usr/local

The *build_command* can also be set via the **MAGICMAKE_BUILD_CMD** environment variable:

    MAGICMAKE_BUILD_CMD="./configure --prefix=/usr/local" magicmake

For convenience, you might want to export **MAGICMAKE_BUILD_CMD** if frequently reused:

    export MAGICMAKE_BUILD_CMD="./configure --prefix=/usr/local"
    magicmake

<h2 id="rationale">3. Rationale</h2>

It is sometimes necessary to install a project from source,
when it's not included in the distribution's package management system.

Many projects document build prerequisites in the `README`,
with instructions on the exact package names that needs to be installed,
for different distributions.

However, if it doesn't say exactly what packages that needs to be installed
for your distribution, it can be a tedious manual task to figure it out,
using [apt-file] or a search engine.

`magicmake` is primarily meant to be useful when working locally trying out
new projects in a virtualized environment, rather than to be used in production,
even if doing so should be relatively harmless, as it will display a Yes/no prompt
for each suggested package to install.

Also, if it's necessary to script the building and installation of
completely unknown projects, if just wanting to test if such projects
can be built and to run the tests, it doesn't help if the `README`
contains human readable instructions.

There are probably many other reasons why this tool is a bad idea in general,
but is meant to provide a lazy way to build projects,
when really insisting on trying to automate the process,
that sometimes works and sometimes doesn't, which might be acceptable to some users,
in some cases.

<h2 id="dependencies">4. Dependencies</h2>

`magicmake` currently only works for Ubuntu. The concept is probably compatible with other distros,
but as the author is only using Ubuntu, no effort has been made to port it to other distros.

  - Ubuntu 20.04.2 LTS *(might work with other versions, but not tested)*
  - apt-file
  - PostgreSQL
  - bpfcc-tools

<h2 id="installation">5. Installation</h2>

Install dependencies:

    sudo apt-get update
    sudo apt-get install -y postgresql postgresql-server-dev-12 apt-file bpfcc-tools
    sudo apt-file update

Create a PostgreSQL database for your user, if you don't have one already.

    sudo -u postgres createuser -s "$USER"
    createdb -E UTF8 $USER

Install magicmake:

    git clone https://github.com/truthly/magicmake.git
    cd magicmake
    make
    sudo make install
    make installcheck
    psql -c "CREATE EXTENSION magicmake"
    ./update_file_packages.sh | psql
    sudo ln -s "`pg_config --bindir`/magicmake" /usr/local/bin/

<h2 id="demo">6. Demo</h2>

Below are a few examples of using `magicmake` to build various projects.

<h3 id="pguri">https://github.com/petere/pguri.git</h3>

    magicmake@magicmake:~$ git clone https://github.com/petere/pguri.git
    Cloning into 'pguri'...
    remote: Enumerating objects: 171, done.
    remote: Counting objects: 100% (6/6), done.
    remote: Compressing objects: 100% (5/5), done.
    remote: Total 171 (delta 1), reused 4 (delta 1), pack-reused 165
    Receiving objects: 100% (171/171), 39.19 KiB | 321.00 KiB/s, done.
    Resolving deltas: 100% (81/81), done.
    magicmake@magicmake:~$ cd pguri/
    magicmake@magicmake:~/pguri$ magicmake
    [sudo] password for magicmake:
    Makefile:10: liburiparser not registed with pkg-config, build might fail
    Package liburiparser was not found in the pkg-config search path.
    Perhaps you should add the directory containing `liburiparser.pc'
    to the PKG_CONFIG_PATH environment variable
    No package 'liburiparser' found
    gcc -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Werror=vla -Wendif-labels -Wmissing-format-attribute -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -Wno-format-truncation -Wno-stringop-truncation -g -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fno-omit-frame-pointer -fPIC  -I. -I./ -I/usr/include/postgresql/12/server -I/usr/include/postgresql/internal  -Wdate-time -D_FORTIFY_SOURCE=2 -D_GNU_SOURCE -I/usr/include/libxml2  -I/usr/include/mit-krb5  -c -o uri.o uri.c
    uri.c:1:10: fatal error: postgres.h: No such file or directory
        1 | #include <postgres.h>
          |          ^~~~~~~~~~~~
    compilation terminated.
    make: *** [<builtin>: uri.o] Error 1
    🪄 🤖 magicmake: do you want to install liburiparser-dev? [y/n] y
    Reading package lists... Done
    Building dependency tree
    Reading state information... Done
    The following additional packages will be installed:
      liburiparser1
    The following NEW packages will be installed:
      liburiparser-dev liburiparser1
    0 upgraded, 2 newly installed, 0 to remove and 0 not upgraded.
    Need to get 51.3 kB of archives.
    After this operation, 229 kB of additional disk space will be used.
    Do you want to continue? [Y/n]
    Get:1 http://se.archive.ubuntu.com/ubuntu focal/universe amd64 liburiparser1 amd64 0.9.3-2 [39.3 kB]
    Get:2 http://se.archive.ubuntu.com/ubuntu focal/universe amd64 liburiparser-dev amd64 0.9.3-2 [12.0 kB]
    Fetched 51.3 kB in 0s (427 kB/s)
    Selecting previously unselected package liburiparser1:amd64.
    (Reading database ... 78797 files and directories currently installed.)
    Preparing to unpack .../liburiparser1_0.9.3-2_amd64.deb ...
    Unpacking liburiparser1:amd64 (0.9.3-2) ...
    Selecting previously unselected package liburiparser-dev.
    Preparing to unpack .../liburiparser-dev_0.9.3-2_amd64.deb ...
    Unpacking liburiparser-dev (0.9.3-2) ...
    Setting up liburiparser1:amd64 (0.9.3-2) ...
    Setting up liburiparser-dev (0.9.3-2) ...
    Processing triggers for libc-bin (2.31-0ubuntu9.2) ...
    gcc -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Werror=vla -Wendif-labels -Wmissing-format-attribute -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -Wno-format-truncation -Wno-stringop-truncation -g -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fno-omit-frame-pointer -fPIC  -I. -I./ -I/usr/include/postgresql/12/server -I/usr/include/postgresql/internal  -Wdate-time -D_FORTIFY_SOURCE=2 -D_GNU_SOURCE -I/usr/include/libxml2  -I/usr/include/mit-krb5  -c -o uri.o uri.c
    uri.c:1:10: fatal error: postgres.h: No such file or directory
        1 | #include <postgres.h>
          |          ^~~~~~~~~~~~
    compilation terminated.
    make: *** [<builtin>: uri.o] Error 1
    🪄 🤖 magicmake: do you want to install postgresql-server-dev-12? [y/n] y
    Reading package lists... Done
    Building dependency tree
    Reading state information... Done
    The following additional packages will be installed:
      binfmt-support clang-10 lib32gcc-s1 lib32stdc++6 libc6-i386
      libclang-common-10-dev libclang-cpp10 libclang1-10 libffi-dev libgc1c2
      libobjc-9-dev libobjc4 libomp-10-dev libomp5-10 libpfm4 libpq-dev
      libstdc++-9-dev libz3-4 libz3-dev llvm-10 llvm-10-dev llvm-10-runtime
      llvm-10-tools python3-pygments
    Suggested packages:
      clang-10-doc libomp-10-doc postgresql-doc-12 libstdc++-9-doc llvm-10-doc
      python-pygments-doc ttf-bitstream-vera
    The following NEW packages will be installed:
      binfmt-support clang-10 lib32gcc-s1 lib32stdc++6 libc6-i386
      libclang-common-10-dev libclang-cpp10 libclang1-10 libffi-dev libgc1c2
      libobjc-9-dev libobjc4 libomp-10-dev libomp5-10 libpfm4 libpq-dev
      libstdc++-9-dev libz3-4 libz3-dev llvm-10 llvm-10-dev llvm-10-runtime
      llvm-10-tools postgresql-server-dev-12 python3-pygments
    0 upgraded, 25 newly installed, 0 to remove and 0 not upgraded.
    Need to get 68.9 MB of archives.
    After this operation, 439 MB of additional disk space will be used.
    Do you want to continue? [Y/n]
    Get:1 http://se.archive.ubuntu.com/ubuntu focal/universe amd64 binfmt-support amd64 2.2.0-2 [58.2 kB]
    Get:3 http://se.archive.ubuntu.com/ubuntu focal-updates/main amd64 libstdc++-9-dev amd64 9.3.0-17ubuntu1~20.04 [1714 kB]
    Get:2 http://gemmei.ftp.acc.umu.se/ubuntu focal/universe amd64 libclang-cpp10 amd64 1:10.0.0-4ubuntu1 [9944 kB]
    Get:4 http://se.archive.ubuntu.com/ubuntu focal/main amd64 libgc1c2 amd64 1:7.6.4-0.4ubuntu1 [83.9 kB]
    Get:5 http://se.archive.ubuntu.com/ubuntu focal-updates/universe amd64 libobjc4 amd64 10.2.0-5ubuntu1~20.04 [42.8 kB]
    Get:6 http://se.archive.ubuntu.com/ubuntu focal-updates/universe amd64 libobjc-9-dev amd64 9.3.0-17ubuntu1~20.04 [226 kB]
    Get:7 http://se.archive.ubuntu.com/ubuntu focal-updates/main amd64 libc6-i386 amd64 2.31-0ubuntu9.2 [2723 kB]
    Get:8 http://se.archive.ubuntu.com/ubuntu focal-updates/main amd64 lib32gcc-s1 amd64 10.2.0-5ubuntu1~20.04 [49.6 kB]
    Get:9 http://se.archive.ubuntu.com/ubuntu focal-updates/main amd64 lib32stdc++6 amd64 10.2.0-5ubuntu1~20.04 [525 kB]
    Get:12 http://se.archive.ubuntu.com/ubuntu focal/universe amd64 clang-10 amd64 1:10.0.0-4ubuntu1 [66.9 kB]
    Get:13 http://se.archive.ubuntu.com/ubuntu focal/universe amd64 libomp5-10 amd64 1:10.0.0-4ubuntu1 [300 kB]
    Get:14 http://se.archive.ubuntu.com/ubuntu focal/universe amd64 libomp-10-dev amd64 1:10.0.0-4ubuntu1 [47.7 kB]
    Get:15 http://se.archive.ubuntu.com/ubuntu focal-updates/main amd64 libpq-dev amd64 12.6-0ubuntu0.20.04.1 [136 kB]
    Get:16 http://se.archive.ubuntu.com/ubuntu focal/universe amd64 llvm-10-runtime amd64 1:10.0.0-4ubuntu1 [180 kB]
    Get:17 http://se.archive.ubuntu.com/ubuntu focal/main amd64 libpfm4 amd64 4.10.1+git20-g7700f49-2 [266 kB]
    Get:19 http://se.archive.ubuntu.com/ubuntu focal/main amd64 libffi-dev amd64 3.3-4 [57.0 kB]
    Get:20 http://se.archive.ubuntu.com/ubuntu focal-updates/main amd64 python3-pygments all 2.3.1+dfsg-1ubuntu2.2 [579 kB]
    Get:21 http://se.archive.ubuntu.com/ubuntu focal/universe amd64 llvm-10-tools amd64 1:10.0.0-4ubuntu1 [317 kB]
    Get:23 http://se.archive.ubuntu.com/ubuntu focal/universe amd64 libz3-dev amd64 4.8.7-4build1 [67.5 kB]
    Get:25 http://se.archive.ubuntu.com/ubuntu focal-updates/universe amd64 postgresql-server-dev-12 amd64 12.6-0ubuntu0.20.04.1 [920 kB]
    Get:11 http://chuangtzu.ftp.acc.umu.se/ubuntu focal/universe amd64 libclang1-10 amd64 1:10.0.0-4ubuntu1 [7571 kB]
    Get:10 http://laotzu.ftp.acc.umu.se/ubuntu focal/universe amd64 libclang-common-10-dev amd64 1:10.0.0-4ubuntu1 [5012 kB]
    Get:22 http://saimei.ftp.acc.umu.se/ubuntu focal/universe amd64 libz3-4 amd64 4.8.7-4build1 [6792 kB]
    Get:18 http://chuangtzu.ftp.acc.umu.se/ubuntu focal/universe amd64 llvm-10 amd64 1:10.0.0-4ubuntu1 [5214 kB]
    Get:24 http://saimei.ftp.acc.umu.se/ubuntu focal/universe amd64 llvm-10-dev amd64 1:10.0.0-4ubuntu1 [26.0 MB]
    Fetched 68.9 MB in 2s (38.5 MB/s)
    Selecting previously unselected package binfmt-support.
    (Reading database ... 78814 files and directories currently installed.)
    Preparing to unpack .../00-binfmt-support_2.2.0-2_amd64.deb ...
    Unpacking binfmt-support (2.2.0-2) ...
    Selecting previously unselected package libclang-cpp10.
    Preparing to unpack .../01-libclang-cpp10_1%3a10.0.0-4ubuntu1_amd64.deb ...
    Unpacking libclang-cpp10 (1:10.0.0-4ubuntu1) ...
    Selecting previously unselected package libstdc++-9-dev:amd64.
    Preparing to unpack .../02-libstdc++-9-dev_9.3.0-17ubuntu1~20.04_amd64.deb ...
    Unpacking libstdc++-9-dev:amd64 (9.3.0-17ubuntu1~20.04) ...
    Selecting previously unselected package libgc1c2:amd64.
    Preparing to unpack .../03-libgc1c2_1%3a7.6.4-0.4ubuntu1_amd64.deb ...
    Unpacking libgc1c2:amd64 (1:7.6.4-0.4ubuntu1) ...
    Selecting previously unselected package libobjc4:amd64.
    Preparing to unpack .../04-libobjc4_10.2.0-5ubuntu1~20.04_amd64.deb ...
    Unpacking libobjc4:amd64 (10.2.0-5ubuntu1~20.04) ...
    Selecting previously unselected package libobjc-9-dev:amd64.
    Preparing to unpack .../05-libobjc-9-dev_9.3.0-17ubuntu1~20.04_amd64.deb ...
    Unpacking libobjc-9-dev:amd64 (9.3.0-17ubuntu1~20.04) ...
    Selecting previously unselected package libc6-i386.
    Preparing to unpack .../06-libc6-i386_2.31-0ubuntu9.2_amd64.deb ...
    Unpacking libc6-i386 (2.31-0ubuntu9.2) ...
    Selecting previously unselected package lib32gcc-s1.
    Preparing to unpack .../07-lib32gcc-s1_10.2.0-5ubuntu1~20.04_amd64.deb ...
    Unpacking lib32gcc-s1 (10.2.0-5ubuntu1~20.04) ...
    Selecting previously unselected package lib32stdc++6.
    Preparing to unpack .../08-lib32stdc++6_10.2.0-5ubuntu1~20.04_amd64.deb ...
    Unpacking lib32stdc++6 (10.2.0-5ubuntu1~20.04) ...
    Selecting previously unselected package libclang-common-10-dev.
    Preparing to unpack .../09-libclang-common-10-dev_1%3a10.0.0-4ubuntu1_amd64.deb ...
    Unpacking libclang-common-10-dev (1:10.0.0-4ubuntu1) ...
    Selecting previously unselected package libclang1-10.
    Preparing to unpack .../10-libclang1-10_1%3a10.0.0-4ubuntu1_amd64.deb ...
    Unpacking libclang1-10 (1:10.0.0-4ubuntu1) ...
    Selecting previously unselected package clang-10.
    Preparing to unpack .../11-clang-10_1%3a10.0.0-4ubuntu1_amd64.deb ...
    Unpacking clang-10 (1:10.0.0-4ubuntu1) ...
    Selecting previously unselected package libomp5-10:amd64.
    Preparing to unpack .../12-libomp5-10_1%3a10.0.0-4ubuntu1_amd64.deb ...
    Unpacking libomp5-10:amd64 (1:10.0.0-4ubuntu1) ...
    Selecting previously unselected package libomp-10-dev.
    Preparing to unpack .../13-libomp-10-dev_1%3a10.0.0-4ubuntu1_amd64.deb ...
    Unpacking libomp-10-dev (1:10.0.0-4ubuntu1) ...
    Selecting previously unselected package libpq-dev.
    Preparing to unpack .../14-libpq-dev_12.6-0ubuntu0.20.04.1_amd64.deb ...
    Unpacking libpq-dev (12.6-0ubuntu0.20.04.1) ...
    Selecting previously unselected package llvm-10-runtime.
    Preparing to unpack .../15-llvm-10-runtime_1%3a10.0.0-4ubuntu1_amd64.deb ...
    Unpacking llvm-10-runtime (1:10.0.0-4ubuntu1) ...
    Selecting previously unselected package libpfm4:amd64.
    Preparing to unpack .../16-libpfm4_4.10.1+git20-g7700f49-2_amd64.deb ...
    Unpacking libpfm4:amd64 (4.10.1+git20-g7700f49-2) ...
    Selecting previously unselected package llvm-10.
    Preparing to unpack .../17-llvm-10_1%3a10.0.0-4ubuntu1_amd64.deb ...
    Unpacking llvm-10 (1:10.0.0-4ubuntu1) ...
    Selecting previously unselected package libffi-dev:amd64.
    Preparing to unpack .../18-libffi-dev_3.3-4_amd64.deb ...
    Unpacking libffi-dev:amd64 (3.3-4) ...
    Selecting previously unselected package python3-pygments.
    Preparing to unpack .../19-python3-pygments_2.3.1+dfsg-1ubuntu2.2_all.deb ...
    Unpacking python3-pygments (2.3.1+dfsg-1ubuntu2.2) ...
    Selecting previously unselected package llvm-10-tools.
    Preparing to unpack .../20-llvm-10-tools_1%3a10.0.0-4ubuntu1_amd64.deb ...
    Unpacking llvm-10-tools (1:10.0.0-4ubuntu1) ...
    Selecting previously unselected package libz3-4:amd64.
    Preparing to unpack .../21-libz3-4_4.8.7-4build1_amd64.deb ...
    Unpacking libz3-4:amd64 (4.8.7-4build1) ...
    Selecting previously unselected package libz3-dev:amd64.
    Preparing to unpack .../22-libz3-dev_4.8.7-4build1_amd64.deb ...
    Unpacking libz3-dev:amd64 (4.8.7-4build1) ...
    Selecting previously unselected package llvm-10-dev.
    Preparing to unpack .../23-llvm-10-dev_1%3a10.0.0-4ubuntu1_amd64.deb ...
    Unpacking llvm-10-dev (1:10.0.0-4ubuntu1) ...
    Selecting previously unselected package postgresql-server-dev-12.
    Preparing to unpack .../24-postgresql-server-dev-12_12.6-0ubuntu0.20.04.1_amd64.deb ...
    Unpacking postgresql-server-dev-12 (12.6-0ubuntu0.20.04.1) ...
    Setting up libstdc++-9-dev:amd64 (9.3.0-17ubuntu1~20.04) ...
    Setting up libgc1c2:amd64 (1:7.6.4-0.4ubuntu1) ...
    Setting up libpq-dev (12.6-0ubuntu0.20.04.1) ...
    Setting up libobjc4:amd64 (10.2.0-5ubuntu1~20.04) ...
    Setting up libffi-dev:amd64 (3.3-4) ...
    Setting up libclang-cpp10 (1:10.0.0-4ubuntu1) ...
    Setting up python3-pygments (2.3.1+dfsg-1ubuntu2.2) ...
    Setting up libz3-4:amd64 (4.8.7-4build1) ...
    Setting up libpfm4:amd64 (4.10.1+git20-g7700f49-2) ...
    Setting up libclang1-10 (1:10.0.0-4ubuntu1) ...
    Setting up binfmt-support (2.2.0-2) ...
    Created symlink /etc/systemd/system/multi-user.target.wants/binfmt-support.service → /lib/systemd/system/binfmt-support.service.
    Setting up libobjc-9-dev:amd64 (9.3.0-17ubuntu1~20.04) ...
    Setting up libomp5-10:amd64 (1:10.0.0-4ubuntu1) ...
    Setting up libc6-i386 (2.31-0ubuntu9.2) ...
    Setting up libz3-dev:amd64 (4.8.7-4build1) ...
    Setting up llvm-10-tools (1:10.0.0-4ubuntu1) ...
    Setting up libomp-10-dev (1:10.0.0-4ubuntu1) ...
    Setting up llvm-10-runtime (1:10.0.0-4ubuntu1) ...
    Setting up lib32gcc-s1 (10.2.0-5ubuntu1~20.04) ...
    Setting up lib32stdc++6 (10.2.0-5ubuntu1~20.04) ...
    Setting up libclang-common-10-dev (1:10.0.0-4ubuntu1) ...
    Setting up llvm-10 (1:10.0.0-4ubuntu1) ...
    Setting up llvm-10-dev (1:10.0.0-4ubuntu1) ...
    Setting up clang-10 (1:10.0.0-4ubuntu1) ...
    Setting up postgresql-server-dev-12 (12.6-0ubuntu0.20.04.1) ...
    Processing triggers for systemd (245.4-4ubuntu3.6) ...
    Processing triggers for man-db (2.9.1-1) ...
    Processing triggers for install-info (6.7.0.dfsg.2-5) ...
    Processing triggers for libc-bin (2.31-0ubuntu9.2) ...
    gcc -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Werror=vla -Wendif-labels -Wmissing-format-attribute -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -Wno-format-truncation -Wno-stringop-truncation -g -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fno-omit-frame-pointer -fPIC  -I. -I./ -I/usr/include/postgresql/12/server -I/usr/include/postgresql/internal  -Wdate-time -D_FORTIFY_SOURCE=2 -D_GNU_SOURCE -I/usr/include/libxml2  -I/usr/include/mit-krb5  -c -o uri.o uri.c
    gcc -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Werror=vla -Wendif-labels -Wmissing-format-attribute -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -Wno-format-truncation -Wno-stringop-truncation -g -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fno-omit-frame-pointer -fPIC -shared -o uri.so uri.o -L/usr/lib/x86_64-linux-gnu  -Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -L/usr/lib/llvm-10/lib  -L/usr/lib/x86_64-linux-gnu/mit-krb5 -Wl,--as-needed  -luriparser
    /usr/bin/clang-10 -Wno-ignored-attributes -fno-strict-aliasing -fwrapv -O2   -I. -I./ -I/usr/include/postgresql/12/server -I/usr/include/postgresql/internal  -Wdate-time -D_FORTIFY_SOURCE=2 -D_GNU_SOURCE -I/usr/include/libxml2  -I/usr/include/mit-krb5 -flto=thin -emit-llvm -c -o uri.bc uri.c
    🪄 🤖 magicmake: do you want to install lib32gcc-9-dev? [y/n] n
    🪄 🤖 magicmake: do you want to install libx32gcc-9-dev? [y/n] n
    🪄 🤖 magicmake: do you want to install nvidia-cuda-toolkit? [y/n] n
    make: Nothing to be done for 'all'.
    🪄 🤖 magicmake: no more packages to install ✅
    installed:  liburiparser-dev postgresql-server-dev-12
    not installed:  lib32gcc-9-dev libx32gcc-9-dev nvidia-cuda-toolkit
    magicmake@magicmake:~/pguri$

<h3 id="pgsql-http">https://github.com/pramsey/pgsql-http.git</h3>

    magicmake@magicmake:~$ git clone https://github.com/pramsey/pgsql-http.git
    Cloning into 'pgsql-http'...
    remote: Enumerating objects: 850, done.
    remote: Counting objects: 100% (52/52), done.
    remote: Compressing objects: 100% (34/34), done.
    remote: Total 850 (delta 24), reused 32 (delta 12), pack-reused 798
    Receiving objects: 100% (850/850), 253.31 KiB | 3.67 MiB/s, done.
    Resolving deltas: 100% (521/521), done.
    magicmake@magicmake:~$ cd pgsql-http/
    magicmake@magicmake:~/pgsql-http$ magicmake
    make: curl-config: Command not found
    gcc -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Werror=vla -Wendif-labels -Wmissing-format-attribute -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -Wno-format-truncation -Wno-stringop-truncation -g -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fno-omit-frame-pointer -fPIC -I. -I./ -I/usr/include/postgresql/12/server -I/usr/include/postgresql/internal  -Wdate-time -D_FORTIFY_SOURCE=2 -D_GNU_SOURCE -I/usr/include/libxml2  -I/usr/include/mit-krb5  -c -o http.o http.c
    http.c:72:10: fatal error: curl/curl.h: No such file or directory
      72 | #include <curl/curl.h>
          |          ^~~~~~~~~~~~~
    compilation terminated.
    make: *** [<builtin>: http.o] Error 1
    🪄 🤖 magicmake: there are multiple packages to choose between, please select which one to install (or n to skip):
    1) libcurl4-gnutls-dev
    2) libcurl4-nss-dev
    3) libcurl4-openssl-dev
    #? 3
    🪄 🤖 magicmake: installing libcurl4-openssl-dev
    Reading package lists... Done
    Building dependency tree
    Reading state information... Done
    Suggested packages:
      libcurl4-doc libidn11-dev libkrb5-dev libldap2-dev librtmp-dev libssh2-1-dev
      libssl-dev
    The following NEW packages will be installed:
      libcurl4-openssl-dev
    0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.
    Need to get 321 kB of archives.
    After this operation, 1539 kB of additional disk space will be used.
    Get:1 http://se.archive.ubuntu.com/ubuntu focal-updates/main amd64 libcurl4-openssl-dev amd64 7.68.0-1ubuntu2.5 [321 kB]
    Fetched 321 kB in 0s (2846 kB/s)
    Selecting previously unselected package libcurl4-openssl-dev:amd64.
    (Reading database ... 83866 files and directories currently installed.)
    Preparing to unpack .../libcurl4-openssl-dev_7.68.0-1ubuntu2.5_amd64.deb ...
    Unpacking libcurl4-openssl-dev:amd64 (7.68.0-1ubuntu2.5) ...
    Setting up libcurl4-openssl-dev:amd64 (7.68.0-1ubuntu2.5) ...
    Processing triggers for man-db (2.9.1-1) ...
    gcc -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Werror=vla -Wendif-labels -Wmissing-format-attribute -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -Wno-format-truncation -Wno-stringop-truncation -g -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fno-omit-frame-pointer -fPIC -I. -I./ -I/usr/include/postgresql/12/server -I/usr/include/postgresql/internal  -Wdate-time -D_FORTIFY_SOURCE=2 -D_GNU_SOURCE -I/usr/include/libxml2  -I/usr/include/mit-krb5  -c -o http.o http.c
    gcc -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Werror=vla -Wendif-labels -Wmissing-format-attribute -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -Wno-format-truncation -Wno-stringop-truncation -g -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fno-omit-frame-pointer -fPIC -shared -o http.so http.o -L/usr/lib/x86_64-linux-gnu  -Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -L/usr/lib/llvm-10/lib  -L/usr/lib/x86_64-linux-gnu/mit-krb5 -Wl,--as-needed  -lcurl
    /usr/bin/clang-10 -Wno-ignored-attributes -fno-strict-aliasing -fwrapv -O2  -I. -I./ -I/usr/include/postgresql/12/server -I/usr/include/postgresql/internal  -Wdate-time -D_FORTIFY_SOURCE=2 -D_GNU_SOURCE -I/usr/include/libxml2  -I/usr/include/mit-krb5 -flto=thin -emit-llvm -c -o http.bc http.c
    🪄 🤖 magicmake: no more packages to install ✅
    installed:  libcurl4-openssl-dev
    magicmake@magicmake:~/pgsql-http$

<h2 id="implementation">7. Implementation</h2>

<h3 id="apt-lists">/var/lib/apt/lists</h3>

`magicmake` relies on `apt-file` to download the Ubuntu package management system's
*Contents*-files, which are two column text file databases,
with lists of the `file_path` for all files provided by `packages`.

    sudo apt-file update

`apt-file` compresses the files and store them in `/var/lib/apt/lists`

    $ cd /var/lib/apt/lists
    $ ls -sh *.lz4
    16K se.archive.ubuntu.com_ubuntu_dists_focal-backports_Contents-amd64.lz4
    56M se.archive.ubuntu.com_ubuntu_dists_focal-security_Contents-amd64.lz4
    65M se.archive.ubuntu.com_ubuntu_dists_focal-updates_Contents-amd64.lz4
    66M se.archive.ubuntu.com_ubuntu_dists_focal_Contents-amd64.lz4

Uncompressed, these files contain millions of rows

    $ lz4 -m -c /var/lib/apt/lists/*.lz4 | wc -l
    19490928

`apt-file search` reads such files from beginning to the end,
each time a search is performed, which is not very fast,
but probably acceptable for single searches.

    $ time apt-file search -F /usr/include/uriparser/Uri.h
    liburiparser-dev: /usr/include/uriparser/Uri.h

    real  0m1.806s
    user  0m1.873s
    sys   0m1.195s

To speed-up such searches `magicmake` reads these files only once upon installation,
imports them into a [PostgreSQL] database and creates a [btree] index on the `file_name` column.

Importing them to [PostgreSQL] is not trivial, since there is no single separator character,
instead a mix of tab characters and blank spaces are used, seemingly to visually align the second
column.

The below example has been manually adjusted using only blank spaces to demonstrate the alignment.

    $ lz4 -c -m /var/lib/apt/lists/*.lz4 | head
    etc/issue.d/cockpit.issue                                    universe/admin/cockpit-ws
    etc/motd.d/cockpit                                           universe/admin/cockpit-ws
    etc/pam.d/cockpit                                            universe/admin/cockpit-ws
    lib/systemd/system/cockpit-motd.service                      universe/admin/cockpit-ws
    lib/systemd/system/cockpit-wsinstance-http-redirect.service  universe/admin/cockpit-ws
    lib/systemd/system/cockpit-wsinstance-http-redirect.socket   universe/admin/cockpit-ws
    lib/systemd/system/cockpit-wsinstance-http.service           universe/admin/cockpit-ws
    lib/systemd/system/cockpit-wsinstance-http.socket            universe/admin/cockpit-ws
    lib/systemd/system/cockpit-wsinstance-https-factory.socket   universe/admin/cockpit-ws
    lib/systemd/system/cockpit-wsinstance-https-factory@.service universe/admin/cockpit-ws

This is further complicated since `file_path` may contain unescaped unquoted blank spaces in `file_path`.
The command below shows an example of the ten shortest such cases.

    $ lz4 -c -m /var/lib/apt/lists/*.lz4 | grep -P "[ \t][^ \t]+[ \t]" | awk '{ print length, $0 }' | sort -n -s | cut -d" " -f2- | head -n 10
    usr/share/kazam/sounds/Canon 7D.ogg           universe/video/kazam
    usr/share/kazam/sounds/Canon 7D.ogg           universe/video/kazam
    usr/share/muse/themes/Dark Theme.cfg          universe/sound/muse
    usr/share/muse/themes/Dark Theme.qss          universe/sound/muse
    usr/share/kazam/sounds/Nikon D80.ogg          universe/video/kazam
    usr/share/fmit/scales/Carlos Beta.scl         universe/sound/fmit
    usr/share/kazam/sounds/Nikon D80.ogg          universe/video/kazam
    usr/share/kile/scripts/remove command.js      universe/tex/kile
    usr/share/muse/themes/Light Theme.cfg         universe/sound/muse
    usr/share/higan/Game Boy.sys/boot.rom         universe/games/higan

<h3 id="update-file-packages">update_file_packages.sh</h3>

To import these text files into [PostgreSQL], we need to do some preprocessing,
using `awk`, handled by the script [update_file_packages.sh].

<h3 id="file-packages">magicmake.file_packages table</h3>

The file packages database is loaded into the [magicmake.file_packages] table.

```sql
CREATE TABLE magicmake.file_packages (
file_path text NOT NULL,
dir_path text NOT NULL,
package text NOT NULL
);
```

The `update_file_packages.sh | psql` command only needs to be run once upon installation,
but can be run again to update [magicmake.file_packages],
after running `apt-file update` to update the `*.lz4` files on disk.

<h3 id="magicmake-command">magicmake command</h3>

`magicmake` will write the `bpfcc-tools` output to temporary files
which will be read by the PostgreSQL's function `magicmake.suggest_packages()`.
The files are made readable by any user to allow PostgreSQL to read it.

`magicmake` will run the build and install commands in a loop,
until no more packages to install can be found.

<h3 id="suggest-packages">magicmake.suggest_packages(trace_files_log text, trace_commands_log text)</h3>

The [magicmake.suggest_packages()] function uses the [magicmake.trace_files] and [magicmake.trace_commands] tables to store the log lines.

[make]: https://en.wikipedia.org/wiki/Make_(software)
[Ubuntu]: https://en.wikipedia.org/wiki/Ubuntu
[deb]: https://en.wikipedia.org/wiki/Deb_(file_format)
[apt]: https://en.wikipedia.org/wiki/APT_(software)
[apt-file]: https://en.wikipedia.org/wiki/APT_(software)#apt-file
[PostgreSQL]: https://www.postgresql.org/
[btree]: https://www.postgresql.org/docs/current/btree-intro.html
[magicmake.suggest_packages()]: https://github.com/truthly/magicmake/blob/master/FUNCTIONS/suggest_packages.sql
[magicmake.trace_files]: https://github.com/truthly/magicmake/blob/master/TABLES/trace_files.sql
[magicmake.trace_commands]: https://github.com/truthly/magicmake/blob/master/TABLES/trace_commands.sql
[magicmake.file_packages]: https://github.com/truthly/magicmake/blob/master/TABLES/file_packages.sql
[magicmake.suggested_packages]: https://github.com/truthly/magicmake/blob/master/TABLES/suggested_packages.sql
