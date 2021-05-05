CREATE TABLE magicmake.strace (
log_line_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
log_line text NOT NULL,
file_path text GENERATED ALWAYS AS ((regexp_match(log_line,'"/([^"]+)"'))[1]) STORED,
file_name text GENERATED ALWAYS AS ((regexp_match(log_line,'"[^"]*?([^/"]+)"'))[1]) STORED,
missing boolean NOT NULL GENERATED ALWAYS AS (log_line LIKE '%ENOENT (No such file or directory)') STORED,
pkg_config text GENERATED ALWAYS AS ((regexp_match(log_line,'^(?:\d+ +)?[a-z]+\("/usr/bin/pkg-config", \["/usr/bin/pkg-config"((?:, "[^"]*")+)\]'))[1]) STORED,
PRIMARY KEY (log_line_id)
);
