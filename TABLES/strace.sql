CREATE TABLE magicmake.strace (
log_line_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
log_line_text text NOT NULL,
file_path text GENERATED ALWAYS AS ((regexp_match(log_line_text,'"/([^"]+)"'))[1]) STORED,
file_name text GENERATED ALWAYS AS ((regexp_match(log_line_text,'"[^"]*?([^/"]+)"'))[1]) STORED,
missing boolean NOT NULL GENERATED ALWAYS AS (log_line_text LIKE '%ENOENT (No such file or directory)') STORED,
PRIMARY KEY (log_line_id)
);
