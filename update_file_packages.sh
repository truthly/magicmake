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
  lz4 -c $apt_list | awk -F "[ \t]" '{col=$NF;NF--;while(length($NF)==0){NF--};print $0 "\t" col}'
  echo "\."
done
echo "CREATE INDEX file_packages_file_name ON magicmake.file_packages (file_name);"
echo "COMMIT;"
