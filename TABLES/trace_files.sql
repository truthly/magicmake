CREATE TABLE magicmake.trace_files (
file_path text NOT NULL,
file_name text NOT NULL,
PRIMARY KEY (file_path)
);

CREATE INDEX ON magicmake.trace_files (file_name);
