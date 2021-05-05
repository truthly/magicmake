CREATE TABLE magicmake.file_packages (
file_path text NOT NULL,
packages text NOT NULL,
file_name text NOT NULL GENERATED ALWAYS AS (right(file_path,strpos(reverse(file_path),'/')-1)) STORED
);
