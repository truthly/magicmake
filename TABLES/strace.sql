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

CREATE INDEX ON magicmake.strace (file_name);
