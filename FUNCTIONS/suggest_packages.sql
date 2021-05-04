CREATE OR REPLACE FUNCTION magicmake.suggest_packages(strace_log_file_path text)
RETURNS text
LANGUAGE plpgsql
AS
$$
DECLARE
_packages text;
BEGIN
--
-- truncate the magicmake.strace table before importing
--
TRUNCATE magicmake.strace;
--
-- parse the strace output by splitting at newlines
-- and filtering out lines that looks like syscalls
--
INSERT INTO magicmake.strace
  (log_line_text)
SELECT
  log_line_text
FROM regexp_split_to_table(pg_read_file(strace_log_file_path),E'\n') AS log_line_text
WHERE log_line_text ~ '^(?:\d+ )?[a-z]+\(';
--
-- match the strace rows against file_packages
--
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
matching_packages AS
(
  SELECT
    packages
  FROM truly_missing
  JOIN magicmake.file_packages
    ON file_packages.file_name = truly_missing.file_name
  AND file_packages.file_path = ANY(truly_missing.file_paths)
)
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
INTO
  _packages
FROM matching_packages;
--
-- return blank space separated list of packages
--
RETURN _packages;
END
$$;
