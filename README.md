<h1 id="top">🪄🤖<code>magicmake</code></h1>

1. [About](#about)
1. [Rationale](#rationale)
1. [Dependencies](#dependencies)
1. [Installation](#installation)
1. [Usage](#usage)
1. [Examples](#examples)
      1. [https://github.com/pramsey/pgsql-http.git]
      1. [https://github.com/petere/pguri.git]
1. [Implementation](#implementation)
      1. [/var/lib/apt/lists]
      1. [update_file_packages.py]
      1. [magicmake.file_packages table]
      1. [magicmake command]
      1. [magicmake.suggest_packages(strace_log_file_path text)]

[/var/lib/apt/lists]: #apt-lists
[update_file_packages.py]: #update-file-packages
[magicmake.file_packages table]: #file-packages
[magicmake command]: #magicmake-command
[magicmake.suggest_packages(strace_log_file_path text)]: #suggest-packages
[https://github.com/pramsey/pgsql-http.git]: #pgsql-http
[https://github.com/petere/pguri.git]: #pguri

<h2 id="about">1. About</h2>

`magicmake` is a command line tool to auto-install all missing packages required to build a project from source.

<h2 id="rationale">2. Rationale</h2>

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
even if doing so should be relatively harmless, as `apt-get install` will
display a Yes/No prompt for each suggested package to install.

Also, if it's necessary to script the building and installation of
completely unknown projects, if just wanting to test if such projects
can be built and to run the tests, it doesn't help if the `README`
contains human readable instructions.

There are probably many other reasons why this tool is a bad idea in general,
but is meant to provide a lazy method way to build projects,
when really insisting on trying to automate the process,
that sometimes works and sometimes doesn't, might might be acceptable to some users.

<h2 id="dependencies">3. Dependencies</h2>

`magicmake` currently only works for Ubuntu. The concept is probably compatible with other distros,
but as the author is only using Ubuntu, no effort has been made to port it to other distros.

  - Ubuntu 20.04.2 LTS
  - apt-file
  - Python3
  - PostgreSQL 13

<h2 id="installation">4. Installation</h2>

Install dependencies:

    sudo apt-get update
    sudo apt-get install -y postgresql postgresql-server-dev-12 build-essential python3 apt-file
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
    ./update_file_packages.py | psql

<h2 id="usage">5. Usage</h2>

    magicmake [build_command [build_arguments]]

Calling `magicmake` with no arguments will invoke `make`

    magicmake

This is the same thing as

    magicmake make

To invoke some other `build_command`, pass it as an argument to `magicmake`

    magicmake ./configure

The `build_command` is invoked with all the `build_arguments`, if any

    magicmake ./configure --prefix=/usr/local

The `build_command` can also be set via the `BUILD_CMD` environment variable

    BUILD_CMD="./configure --prefix=/usr/local" magicmake

For convenience, you might want to export `BUILD_CMD` if frequently reused

    export BUILD_CMD="./configure --prefix=/usr/local"
    magicmake

The default command to default packages is `sudo apt-get install`,
and can be overridden via the `INSTALL_CMD` environment variable

To do a dry-run, set it to `echo`, showing the packages that would have been installed.

    INSTALL_CMD="echo" magicmake

To blindly automatically answer **Yes** to all prompts and to run non-interactively, add the `-y` option to the install command.

    INSTALL_CMD="sudo apt-get -y install" magicmake

<h2 id="examples">6. Examples</h2>

Personally, I'm mostly using `magicmake` to automate the process of building PostgreSQL extensions,
out of which many are not available as Ubuntu packages.

Below are few examples of the full console log of using `magicmake` to install a few PostgreSQL extensions.

<h3 id="pgsql-http">https://github.com/pramsey/pgsql-http.git</h3>

    $ git clone https://github.com/pramsey/pgsql-http.git
    $ cd pgsql-http
    $ magicmake
    make: curl-config: Command not found
    gcc -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Werror=vla -Wendif-labels -Wmissing-format-attribute -Wimplicit-fallthrough=3 -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -Wno-format-truncation -Wno-stringop-truncation -g -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fno-omit-frame-pointer -fPIC -I. -I./ -I/usr/include/postgresql/13/server -I/usr/include/postgresql/internal  -Wdate-time -D_FORTIFY_SOURCE=2 -D_GNU_SOURCE -I/usr/include/libxml2   -c -o http.o http.c
    http.c:72:10: fatal error: curl/curl.h: No such file or directory
      72 | #include <curl/curl.h>
          |          ^~~~~~~~~~~~~
    compilation terminated.
    make: *** [<builtin>: http.o] Error 1
    🪄 🤖 magicmake: installing libcurl4-gnutls-dev
    Reading package lists... Done
    Building dependency tree
    Reading state information... Done
    Suggested packages:
      libcurl4-doc libgnutls28-dev libidn11-dev libkrb5-dev libldap2-dev librtmp-dev libssh2-1-dev zlib1g-dev
    The following NEW packages will be installed:
      libcurl4-gnutls-dev
    0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.
    Need to get 0 B/318 kB of archives.
    After this operation, 1526 kB of additional disk space will be used.
    Selecting previously unselected package libcurl4-gnutls-dev:amd64.
    (Reading database ... 109367 files and directories currently installed.)
    Preparing to unpack .../libcurl4-gnutls-dev_7.68.0-1ubuntu2.5_amd64.deb ...
    Unpacking libcurl4-gnutls-dev:amd64 (7.68.0-1ubuntu2.5) ...
    Setting up libcurl4-gnutls-dev:amd64 (7.68.0-1ubuntu2.5) ...
    Processing triggers for man-db (2.9.1-1) ...
    gcc -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Werror=vla -Wendif-labels -Wmissing-format-attribute -Wimplicit-fallthrough=3 -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -Wno-format-truncation -Wno-stringop-truncation -g -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fno-omit-frame-pointer -fPIC -I. -I./ -I/usr/include/postgresql/13/server -I/usr/include/postgresql/internal  -Wdate-time -D_FORTIFY_SOURCE=2 -D_GNU_SOURCE -I/usr/include/libxml2   -c -o http.o http.c
    gcc -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Werror=vla -Wendif-labels -Wmissing-format-attribute -Wimplicit-fallthrough=3 -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -Wno-format-truncation -Wno-stringop-truncation -g -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fno-omit-frame-pointer -fPIC -shared -o http.so http.o -L/usr/lib/x86_64-linux-gnu  -Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -L/usr/lib/llvm-9/lib  -Wl,--as-needed  -lcurl
    /usr/bin/clang-9 -Wno-ignored-attributes -fno-strict-aliasing -fwrapv -O2  -I. -I./ -I/usr/include/postgresql/13/server -I/usr/include/postgresql/internal  -Wdate-time -D_FORTIFY_SOURCE=2 -D_GNU_SOURCE -I/usr/include/libxml2  -flto=thin -emit-llvm -c -o http.bc http.c
    🪄 🤖 magicmake: no more packages to install ✅

<h3 id="pguri">https://github.com/petere/pguri.git</h3>

    $ git clone https://github.com/petere/pguri.git
    $ cd pguri
    $ magicmake
    Makefile:10: liburiparser not registed with pkg-config, build might fail
    Package liburiparser was not found in the pkg-config search path.
    Perhaps you should add the directory containing `liburiparser.pc'
    to the PKG_CONFIG_PATH environment variable
    No package 'liburiparser' found
    gcc -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Werror=vla -Wendif-labels -Wmissing-format-attribute -Wimplicit-fallthrough=3 -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -Wno-format-truncation -Wno-stringop-truncation -g -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fno-omit-frame-pointer -fPIC  -I. -I./ -I/usr/include/postgresql/13/server -I/usr/include/postgresql/internal  -Wdate-time -D_FORTIFY_SOURCE=2 -D_GNU_SOURCE -I/usr/include/libxml2   -c -o uri.o uri.c
    uri.c:10:10: fatal error: uriparser/Uri.h: No such file or directory
      10 | #include <uriparser/Uri.h>
          |          ^~~~~~~~~~~~~~~~~
    compilation terminated.
    make: *** [<builtin>: uri.o] Error 1
    🪄 🤖 magicmake: installing liburiparser-dev
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
    Selecting previously unselected package liburiparser1:amd64.
    (Reading database ... 109374 files and directories currently installed.)
    Preparing to unpack .../liburiparser1_0.9.3-2_amd64.deb ...
    Unpacking liburiparser1:amd64 (0.9.3-2) ...
    Selecting previously unselected package liburiparser-dev.
    Preparing to unpack .../liburiparser-dev_0.9.3-2_amd64.deb ...
    Unpacking liburiparser-dev (0.9.3-2) ...
    Setting up liburiparser1:amd64 (0.9.3-2) ...
    Setting up liburiparser-dev (0.9.3-2) ...
    Processing triggers for libc-bin (2.31-0ubuntu9.2) ...
    gcc -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Werror=vla -Wendif-labels -Wmissing-format-attribute -Wimplicit-fallthrough=3 -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -Wno-format-truncation -Wno-stringop-truncation -g -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fno-omit-frame-pointer -fPIC  -I. -I./ -I/usr/include/postgresql/13/server -I/usr/include/postgresql/internal  -Wdate-time -D_FORTIFY_SOURCE=2 -D_GNU_SOURCE -I/usr/include/libxml2   -c -o uri.o uri.c
    gcc -Wall -Wmissing-prototypes -Wpointer-arith -Wdeclaration-after-statement -Werror=vla -Wendif-labels -Wmissing-format-attribute -Wimplicit-fallthrough=3 -Wformat-security -fno-strict-aliasing -fwrapv -fexcess-precision=standard -Wno-format-truncation -Wno-stringop-truncation -g -g -O2 -fstack-protector-strong -Wformat -Werror=format-security -fno-omit-frame-pointer -fPIC -shared -o uri.so uri.o -L/usr/lib/x86_64-linux-gnu  -Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now -L/usr/lib/llvm-9/lib  -Wl,--as-needed  -luriparser
    /usr/bin/clang-9 -Wno-ignored-attributes -fno-strict-aliasing -fwrapv -O2   -I. -I./ -I/usr/include/postgresql/13/server -I/usr/include/postgresql/internal  -Wdate-time -D_FORTIFY_SOURCE=2 -D_GNU_SOURCE -I/usr/include/libxml2  -flto=thin -emit-llvm -c -o uri.bc uri.c
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

<h3 id="update-file-packages">update_file_packages.py</h3>

To import these text files into [PostgreSQL], we need to do some preprocessing,
using [Python]'s [rsplit()] method. The below line is from [update_file_packages.py]:

    cols = line.rsplit(maxsplit=1)

This consumes only the first sequence of white space character(s) from the right,
which effectively splits such lines into two columns, as desired.

If readers know of a simpler and efficient way to do this without using Python,
using only standard commands such as `awk`, `sed` or `cut`, please let me know.

<h3 id="file-packages">magicmake.file_packages table</h3>

The file packages database is loaded into the [magicmake.file_packages] table.

```sql
CREATE TABLE magicmake.file_packages (
file_name text NOT NULL,
file_path text NOT NULL,
packages text NOT NULL
);
```

The [update_file_packages.py] command only needs to be run once upon installation,
but can subsequently be run again to update `magicmake.file_packages`,
after running `apt-file update` to update the `*.lz4` files on disk.

After import, [update_file_packages.py] adds a [btree] index on `file_name`.

```sql
CREATE INDEX ON magicmake.file_packages (file_name);
```

<h3 id="magicmake-command">magicmake command</h3>

`magicmake` will write the `strace` output to a temporary `STRACE_FILE`
which will be read by the PostgreSQL's function `magicmake.suggest_packages()`.
The file is made readable by any user to allow PostgreSQL to read it.

    STRACE_FILE=$(mktemp)
    chmod o+r $STRACE_FILE

`magicmake` will run the build and install commands in a loop,
until no more packages to install can be found.

    while true;
    do
      strace -e trace=file -o $STRACE_FILE -f $BUILD_CMD
      PKGS=$(psql -X -t -A -c "SELECT magicmake.suggest_packages('$STRACE_FILE')")
      if [ -z "$PKGS" ]
      then
        echo "$LOG_PREFIX no more packages to install ✅"
        break
      else
        echo "$LOG_PREFIX installing $PKGS"
        $INSTALL_CMD $PKGS
      fi
    done

Finally, it will remove the temporary `STRACE_FILE`.

    rm -f "$STRACE_FILE"

<h3 id="suggest-packages">magicmake.suggest_packages(strace_log_file_path text)</h3>

The [magicmake.suggest_packages()] function uses a table [magicmake.strace] to store the parsed strace log lines.

```sql
CREATE TABLE magicmake.strace (
log_line_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
log_line_text text NOT NULL,
file_path text GENERATED ALWAYS AS ((regexp_match(log_line_text,'"/([^"]+)"'))[1]) STORED,
file_name text GENERATED ALWAYS AS ((regexp_match(log_line_text,'"[^"]*?([^/"]+)"'))[1]) STORED,
missing boolean NOT NULL GENERATED ALWAYS AS (log_line_text LIKE '%ENOENT (No such file or directory)') STORED,
PRIMARY KEY (log_line_id)
);
```

The strace output is read from the `strace_log_file_path` file and written to this table after truncating it.

```sql
TRUNCATE magicmake.strace;
INSERT INTO magicmake.strace
  (log_line_text)
SELECT
  log_line_text
FROM regexp_split_to_table(pg_read_file(strace_log_file_path),E'\n') AS log_line_text
WHERE log_line_text ~ '^(?:\d+ )?[a-z]+\(';
```

The strace log file is splitted on newlines and only lines matching a regex to filter out possible file syscalls are imported.

The aggregate function [bool_or()] is used to find each `file_name` that is missing at least once and not found even once,
and returns each unique `file_name` with an array of all `file_path`s where the `BUILD_CMD` was looking for the file.

```sql
WITH
truly_missing AS
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
matching_packages AS
(
  SELECT
    packages
  FROM strace
  JOIN magicmake.file_packages
    ON file_packages.file_name = strace.file_name
  AND file_packages.file_path = ANY(strace.file_paths)
)
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

`string_agg()` builds a string of all distinct package names,
separated by blank space ` `.

```sql
SELECT
  string_agg
  (
    DISTINCT
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
    ),
    ' '
  )
FROM matching_packages;
```

[strace]: https://en.wikipedia.org/wiki/Strace
[make]: https://en.wikipedia.org/wiki/Make_(software)
[Ubuntu]: https://en.wikipedia.org/wiki/Ubuntu
[deb]: https://en.wikipedia.org/wiki/Deb_(file_format)
[apt]: https://en.wikipedia.org/wiki/APT_(software)
[apt-file]: https://en.wikipedia.org/wiki/APT_(software)#apt-file
[PostgreSQL]: https://www.postgresql.org/
[btree]: https://www.postgresql.org/docs/current/btree-intro.html
[Python]: https://www.python.org/
[rsplit()]: https://www.w3schools.com/python/ref_string_rsplit.asp
[bool_or()]: https://www.postgresql.org/docs/current/functions-aggregate.html#FUNCTIONS-AGGREGATE-TABLE
[magicmake.suggest_packages()]: https://github.com/truthly/magicmake/blob/master/FUNCTIONS/suggest_packages.sql
[magicmake.strace]: https://github.com/truthly/magicmake/blob/master/TABLES/strace.sql
[magicmake.file_packages]: https://github.com/truthly/magicmake/blob/master/TABLES/file_packages.sql
