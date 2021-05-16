#!/bin/bash
shopt -s extglob
cat <<EOF
\set ON_ERROR_STOP on
BEGIN;
SET work_mem TO '1GB';
DROP TABLE IF EXISTS magicmake.package_dirs;
DROP INDEX IF EXISTS file_packages_file_path_idx;
DROP INDEX IF EXISTS file_packages_package_idx;
TRUNCATE magicmake.import_apt_lists, magicmake.file_packages;
\echo Please wait, this might take several minutes...
EOF
apt_files=/var/lib/apt/lists/*([a-z0-9_.])_Contents-amd64.lz4
for apt_file in $apt_files
do
  echo "\\echo Importing $apt_file"
  echo "COPY magicmake.import_apt_lists (file_path, packages) FROM stdin;"
  lz4 -c "$apt_file" | awk -F "[ \t]" '{col=$NF;NF--;while(length($NF)==0){NF--}; print $0 "\t" col }'
  echo "\."
done
cat <<EOF
INSERT INTO magicmake.file_packages
  (file_path, dir_path, package)
SELECT
  file_path,
  left(file_path,-strpos(reverse(file_path),'/')),
  substring(regexp_split_to_table(packages,',') from '[^/]+$')
FROM magicmake.import_apt_lists;

CREATE INDEX ON magicmake.file_packages (file_path);
CREATE INDEX ON magicmake.file_packages USING GIN (file_path gin_trgm_ops);
CREATE INDEX ON magicmake.file_packages (dir_path);
CREATE INDEX ON magicmake.file_packages (package);
CREATE INDEX ON magicmake.file_packages (package);

CREATE TABLE magicmake.package_dirs AS
SELECT DISTINCT
  left(file_path,-strpos(reverse(file_path),'/')) AS dir_path
FROM magicmake.file_packages;

ALTER TABLE magicmake.package_dirs ADD PRIMARY KEY (dir_path);

COMMIT;
EOF
