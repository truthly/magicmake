<h1 id="top">🪄🤖<code>magicmake</code></h1>

1. [About](#about)
1. [Usage](#usage)
      1. [Options](#options)
      1. [Examples](#examples)
1. [Rationale](#rationale)
1. [Dependencies](#dependencies)
1. [Installation](#installation)
1. [Demo](#demo)
      1. [https://github.com/pramsey/pgsql-http.git](#pgsql-http)
      1. [https://github.com/petere/pguri.git](#pguri)
1. [Implementation](#implementation)
      1. [/var/lib/apt/lists](#apt-lists)
      1. [update_file_packages.sh](#update-file-packages)
      1. [magicmake.file_packages](#file-packages)
      1. [magicmake command](#magicmake-command)
      1. [magicmake.suggest_packages(strace_log_file_path text)](#suggest-packages)

<h2 id="about">1. About</h2>

**magicmake**: detect and install missing packages when building from source

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

<h2 id="installation">5. Installation</h2>

Install dependencies:

    sudo apt-get update
    sudo apt-get install -y postgresql postgresql-server-dev-12 build-essential apt-file
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

Personally, I'm mostly using `magicmake` to automate the process of building PostgreSQL extensions,
out of which many are not available as Ubuntu packages.

Below are few examples of the full console log of using `magicmake` to install a few PostgreSQL extensions.

<h3 id="pgsql-http">https://github.com/pramsey/pgsql-http.git</h3>

    $ git clone https://github.com/pramsey/pgsql-http.git
    $ cd pgsql-http
    $ magicmake
    make: curl-config: Command not found
    gcc -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Werror=vla -Wendif-labels -Wmissing-format-attribute -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -Wno-format-truncation -Wno-stringop-truncation -g -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fno-omit-frame-pointer -fPIC -I. -I./ -I/usr/include/postgresql/12/server -I/usr/include/postgresql/internal  -Wdate-time -D_FORTIFY_SOURCE=2 -D_GNU_SOURCE -I/usr/include/libxml2  -I/usr/include/mit-krb5  -c -o http.o http.c
    http.c:72:10: fatal error: curl/curl.h: No such file or directory
      72 | #include <curl/curl.h>
          |          ^~~~~~~~~~~~~
    compilation terminated.
    make: *** [<builtin>: http.o] Error 1
    🪄 🤖 magicmake: Do you want to install libcurl4-gnutls-dev? [Y/n] y
    Reading package lists... Done
    Building dependency tree
    Reading state information... Done
    Suggested packages:
      libcurl4-doc libgnutls28-dev libidn11-dev libkrb5-dev libldap2-dev librtmp-dev libssh2-1-dev pkg-config zlib1g-dev
    The following NEW packages will be installed:
      libcurl4-gnutls-dev
    0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.
    Need to get 0 B/318 kB of archives.
    After this operation, 1526 kB of additional disk space will be used.
    Selecting previously unselected package libcurl4-gnutls-dev:amd64.
    (Reading database ... 83204 files and directories currently installed.)
    Preparing to unpack .../libcurl4-gnutls-dev_7.68.0-1ubuntu2.5_amd64.deb ...
    Unpacking libcurl4-gnutls-dev:amd64 (7.68.0-1ubuntu2.5) ...
    Setting up libcurl4-gnutls-dev:amd64 (7.68.0-1ubuntu2.5) ...
    Processing triggers for man-db (2.9.1-1) ...
    gcc -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Werror=vla -Wendif-labels -Wmissing-format-attribute -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -Wno-format-truncation -Wno-stringop-truncation -g -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fno-omit-frame-pointer -fPIC -I. -I./ -I/usr/include/postgresql/12/server -I/usr/include/postgresql/internal  -Wdate-time -D_FORTIFY_SOURCE=2 -D_GNU_SOURCE -I/usr/include/libxml2  -I/usr/include/mit-krb5  -c -o http.o http.c
    gcc -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Werror=vla -Wendif-labels -Wmissing-format-attribute -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -Wno-format-truncation -Wno-stringop-truncation -g -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fno-omit-frame-pointer -fPIC -shared -o http.so http.o -L/usr/lib/x86_64-linux-gnu  -Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -L/usr/lib/llvm-10/lib  -L/usr/lib/x86_64-linux-gnu/mit-krb5 -Wl,--as-needed  -lcurl
    /usr/bin/clang-10 -Wno-ignored-attributes -fno-strict-aliasing -fwrapv -O2  -I. -I./ -I/usr/include/postgresql/12/server -I/usr/include/postgresql/internal  -Wdate-time -D_FORTIFY_SOURCE=2 -D_GNU_SOURCE -I/usr/include/libxml2  -I/usr/include/mit-krb5 -flto=thin -emit-llvm -c -o http.bc http.c
    🪄 🤖 magicmake: Do you want to install nvidia-cuda-toolkit? [Y/n] n
    make: Nothing to be done for 'all'.
    🪄 🤖 magicmake: no more packages to install ✅

<h3 id="pguri">https://github.com/petere/pguri.git</h3>

    $ git clone https://github.com/petere/pguri.git
    $ cd pguri
    $ magicmake
    /bin/sh: 1: pkg-config: not found
    Makefile:10: liburiparser not registed with pkg-config, build might fail
    make: pkg-config: Command not found
    gcc -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Werror=vla -Wendif-labels -Wmissing-format-attribute -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -Wno-format-truncation -Wno-stringop-truncation -g -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fno-omit-frame-pointer -fPIC  -I. -I./ -I/usr/include/postgresql/12/server -I/usr/include/postgresql/internal  -Wdate-time -D_FORTIFY_SOURCE=2 -D_GNU_SOURCE -I/usr/include/libxml2  -I/usr/include/mit-krb5  -c -o uri.o uri.c
    uri.c:10:10: fatal error: uriparser/Uri.h: No such file or directory
      10 | #include <uriparser/Uri.h>
          |          ^~~~~~~~~~~~~~~~~
    compilation terminated.
    make: *** [<builtin>: uri.o] Error 1
    🪄 🤖 magicmake: Do you want to install liburiparser-dev? [Y/n] y
    Reading package lists... Done
    Building dependency tree
    Reading state information... Done
    The following additional packages will be installed:
      liburiparser1
    The following NEW packages will be installed:
      liburiparser-dev liburiparser1
    0 upgraded, 2 newly installed, 0 to remove and 0 not upgraded.
    Need to get 0 B/51.3 kB of archives.
    After this operation, 229 kB of additional disk space will be used.
    Do you want to continue? [Y/n] y
    Selecting previously unselected package liburiparser1:amd64.
    (Reading database ... 83229 files and directories currently installed.)
    Preparing to unpack .../liburiparser1_0.9.3-2_amd64.deb ...
    Unpacking liburiparser1:amd64 (0.9.3-2) ...
    Selecting previously unselected package liburiparser-dev.
    Preparing to unpack .../liburiparser-dev_0.9.3-2_amd64.deb ...
    Unpacking liburiparser-dev (0.9.3-2) ...
    Setting up liburiparser1:amd64 (0.9.3-2) ...
    Setting up liburiparser-dev (0.9.3-2) ...
    Processing triggers for libc-bin (2.31-0ubuntu9.2) ...
    🪄 🤖 magicmake: Do you want to install pkg-config? [Y/n] y
    Reading package lists... Done
    Building dependency tree
    Reading state information... Done
    The following NEW packages will be installed:
      pkg-config
    0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.
    Need to get 45.5 kB of archives.
    After this operation, 195 kB of additional disk space will be used.
    Get:1 http://se.archive.ubuntu.com/ubuntu focal/main amd64 pkg-config amd64 0.29.1-0ubuntu4 [45.5 kB]
    Fetched 45.5 kB in 0s (236 kB/s)
    Selecting previously unselected package pkg-config.
    (Reading database ... 83246 files and directories currently installed.)
    Preparing to unpack .../pkg-config_0.29.1-0ubuntu4_amd64.deb ...
    Unpacking pkg-config (0.29.1-0ubuntu4) ...
    Setting up pkg-config (0.29.1-0ubuntu4) ...
    Processing triggers for man-db (2.9.1-1) ...
    gcc -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Werror=vla -Wendif-labels -Wmissing-format-attribute -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -Wno-format-truncation -Wno-stringop-truncation -g -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fno-omit-frame-pointer -fPIC  -I. -I./ -I/usr/include/postgresql/12/server -I/usr/include/postgresql/internal  -Wdate-time -D_FORTIFY_SOURCE=2 -D_GNU_SOURCE -I/usr/include/libxml2  -I/usr/include/mit-krb5  -c -o uri.o uri.c
    gcc -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Werror=vla -Wendif-labels -Wmissing-format-attribute -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -Wno-format-truncation -Wno-stringop-truncation -g -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fno-omit-frame-pointer -fPIC -shared -o uri.so uri.o -L/usr/lib/x86_64-linux-gnu  -Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -L/usr/lib/llvm-10/lib  -L/usr/lib/x86_64-linux-gnu/mit-krb5 -Wl,--as-needed  -luriparser
    /usr/bin/clang-10 -Wno-ignored-attributes -fno-strict-aliasing -fwrapv -O2   -I. -I./ -I/usr/include/postgresql/12/server -I/usr/include/postgresql/internal  -Wdate-time -D_FORTIFY_SOURCE=2 -D_GNU_SOURCE -I/usr/include/libxml2  -I/usr/include/mit-krb5 -flto=thin -emit-llvm -c -o uri.bc uri.c
    🪄 🤖 magicmake: no more packages to install ✅

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
using `awk`, handled by the script [update_file_packages.sh] shown in full below.

```sh
#!/bin/sh
cat <<EOF
BEGIN;
DROP INDEX IF EXISTS magicmake.file_packages_file_name;
TRUNCATE magicmake.file_packages;
\echo 'Please wait, this might take several minutes...'
EOF
for apt_list in /var/lib/apt/lists/*.lz4
do
  echo "\\\echo Importing $apt_list..."
  echo "COPY magicmake.file_packages (file_path, packages) FROM stdin;"
  lz4 -c $apt_list | awk -F "[ \t]+" '{col=$NF;NF--;print $0 "\t" col}'
  echo "\."
done
echo "CREATE INDEX file_packages_file_name ON magicmake.file_packages (file_name);"
echo "COMMIT;"
```

This consumes only the first sequence of white space character(s) from the right,
which effectively splits such lines into two columns, as desired.

<h3 id="file-packages">magicmake.file_packages table</h3>

The file packages database is loaded into the [magicmake.file_packages] table.

```sql
CREATE TABLE magicmake.file_packages (
file_path text NOT NULL,
packages text NOT NULL,
file_name text NOT NULL GENERATED ALWAYS AS (right(file_path,strpos(reverse(file_path),'/')-1)) STORED
);
```

The `update_file_packages.sh | psql` command only needs to be run once upon installation,
but can be run again to update [magicmake.file_packages],
after running `apt-file update` to update the `*.lz4` files on disk.

<h3 id="magicmake-command">magicmake command</h3>

`magicmake` will write the `strace` output to a temporary `strace_log_file`
which will be read by the PostgreSQL's function `magicmake.suggest_packages()`.
The file is made readable by any user to allow PostgreSQL to read it.

```bash
strace_log_file=$(mktemp)
chmod o+r $strace_log_file
```

`magicmake` will run the build and install commands in a loop,
until no more packages to install can be found.

```bash
while true;
do
  strace -e trace=file -o $strace_log_file -f $MAGICMAKE_BUILD_CMD
  count=0
  for package in $(psql -X -t -A -c "SELECT magicmake.suggest_packages('$strace_log_file')")
  do
    count=$((count+1))
    install=0
    if [ $prompt = 0 ]
    then
      install=1
    else
      read -p "$console_msg_prefix Do you want to install [37;1m$package[0m? [Y/n] " -r yes_no
      if [[ "$yes_no" =~ ^[Yy]$ ]] || [[ -z "$yes_no" ]]
      then
        install=1
      else
        install=0
      fi
    fi
    if [ $install = 1 ]
    then
      $MAGICMAKE_INSTALL_CMD $package
    fi
  done
  if [ $count = 0 ]
  then
    echo "$console_msg_prefix no more packages to install ✅"
    break
  fi
done
```

Finally, it will remove the temporary `strace_log_file`.

```bash
rm -f "$strace_log_file"
```

<h3 id="suggest-packages">magicmake.suggest_packages(strace_log_file_path text)</h3>

The [magicmake.suggest_packages()] function uses a table [magicmake.strace] to store the strace log lines.

```sql
CREATE TABLE magicmake.strace (
log_line_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
log_line text NOT NULL,
file_path text GENERATED ALWAYS AS (substring(log_line from '"/([^"]+)"')) STORED,
file_name text GENERATED ALWAYS AS (substring(log_line from '"[^"]*?([^/"]+)"')) STORED,
missing boolean NOT NULL GENERATED ALWAYS AS (log_line LIKE '%ENOENT (No such file or directory)') STORED,
pkg_config text GENERATED ALWAYS AS (substring(log_line from '^[a-z0-9_]+\("/usr/bin/pkg-config", \["/usr/bin/pkg-config"((?:, "[^"]*")+)\]')) STORED,
exit_status int GENERATED ALWAYS AS (substring(log_line from '^[+]{3} exited with (\d+) [+]{3}')::int) STORED,
PRIMARY KEY (log_line_id)
);
```

The strace output is read from the `strace_log_file_path` file and written to this table after truncating it.

```sql
TRUNCATE magicmake.strace;
INSERT INTO magicmake.strace
  (log_line)
SELECT
  log_line
FROM regexp_split_to_table(pg_read_file(strace_log_file_path),E'\n') AS log_line;
```

The strace log file is splitted on newlines and only lines matching a regex to filter out possible file syscalls are imported.

The aggregate function [bool_or()] is used to find each `file_name` that is missing at least once and not found even once,
and returns each unique `file_name` with an array of all `file_path`s where the `MAGICMAKE_BUILD_CMD` was looking for the file.

```sql
WITH
missing_files AS
(
  SELECT
    file_name,
    array_agg(file_path) AS file_paths
  FROM magicmake.strace
  GROUP BY file_name
  HAVING bool_or(missing) AND NOT bool_or(NOT missing)
),
```

`file_name` and `file_paths` from the `strace` query above is then matched against the `magicmake.file_packages` table's corresponding columns.

```sql
missing_packages AS
(
  SELECT
    packages
  FROM missing_files
  JOIN magicmake.file_packages
    ON file_packages.file_name = missing_files.file_name
  AND file_packages.file_path = ANY(missing_files.file_paths)
),
```

`packages` normally only contains one package, but in a few cases
there are multiple separated by comma `,`.

Manual inspection seems to imply the first package is to prefer
in such rare cases.

The below query will discard any such extra packages,
and extract the first package.

The last part of the package path is the package name,
which is extracted using the regular expression `^.*?([^/]+)$`,
which captures the last string of non-slash characters.

```sql
missing_package_names AS
(
  SELECT DISTINCT
    regexp_replace
    (
      --
      -- ignore multiple packages separated by comma,
      -- just pick the first one
      --
      regexp_replace(packages,',.*$',''),
      --
      -- extract the package name
      --
      '^.*?([^/]+)$',
      '\1'
    ) AS package
  FROM missing_packages
),
```

New missing packages that have not been suggested before
are saved to the [magicmake.suggested_packages] table
and returned to the `magicmake` script, which will prompt the
user whether or not to install each suggested package.

```sql
new_missing_packages AS
(
  --
  -- remember what packages have been suggested
  -- to avoid spamming the user, if answering "No"
  -- when prompted if a package should be installed
  --
  INSERT INTO magicmake.suggested_packages
    (package)
  SELECT
    package
  FROM missing_package_names
  WHERE NOT EXISTS
  (
    SELECT 1 FROM magicmake.suggested_packages
    WHERE suggested_packages.package = missing_package_names.package
  )
  RETURNING package
)
SELECT
  package
FROM new_missing_packages;
```

[strace]: https://en.wikipedia.org/wiki/Strace
[make]: https://en.wikipedia.org/wiki/Make_(software)
[Ubuntu]: https://en.wikipedia.org/wiki/Ubuntu
[deb]: https://en.wikipedia.org/wiki/Deb_(file_format)
[apt]: https://en.wikipedia.org/wiki/APT_(software)
[apt-file]: https://en.wikipedia.org/wiki/APT_(software)#apt-file
[PostgreSQL]: https://www.postgresql.org/
[btree]: https://www.postgresql.org/docs/current/btree-intro.html
[bool_or()]: https://www.postgresql.org/docs/current/functions-aggregate.html#FUNCTIONS-AGGREGATE-TABLE
[magicmake.suggest_packages()]: https://github.com/truthly/magicmake/blob/master/FUNCTIONS/suggest_packages.sql
[magicmake.strace]: https://github.com/truthly/magicmake/blob/master/TABLES/strace.sql
[magicmake.file_packages]: https://github.com/truthly/magicmake/blob/master/TABLES/file_packages.sql
[magicmake.suggested_packages]: https://github.com/truthly/magicmake/blob/master/TABLES/suggested_packages.sql
