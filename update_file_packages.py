#!/usr/bin/python3
import io
import subprocess
import glob
import re
parse_file_name = re.compile(r"^.*?([^/]+)$")
files = glob.glob("/var/lib/apt/lists/*.lz4")
proc = subprocess.Popen(["lz4", "-c", "-m"] + files, stdout=subprocess.PIPE)
print('DROP INDEX IF EXISTS magicmake.file_packages_file_name;');
print('TRUNCATE magicmake.file_packages;')
print('COPY magicmake.file_packages (file_name, file_path, packages) FROM stdin;')
for line in io.TextIOWrapper(proc.stdout, encoding="utf-8"):
    cols = line.rsplit(maxsplit=1)
    file_name = parse_file_name.match(cols[0])
    print(file_name.group(1) + '\t' + cols[0] + '\t' + cols[1])
print('\.')
print('CREATE INDEX ON magicmake.file_packages (file_name);')
