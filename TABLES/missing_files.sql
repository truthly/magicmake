CREATE TABLE magicmake.missing_files (
file_name text NOT NULL,
file_paths text[] NOT NULL,
PRIMARY KEY (file_name)
);
