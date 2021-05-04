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
missing_files AS
(
  SELECT
    file_name,
    array_agg(file_path) AS file_paths
  FROM magicmake.strace
  GROUP BY file_name
  HAVING bool_or(missing) AND NOT bool_or(NOT missing)
),
missing_packages AS
(
  SELECT
    packages
  FROM missing_files
  JOIN magicmake.file_packages
    ON file_packages.file_name = missing_files.file_name
  AND file_packages.file_path = ANY(missing_files.file_paths)
),
missing_package_names AS
(
  SELECT DISTINCT
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
    ) AS package
  FROM missing_packages
),
new_missing_packages AS
(
  --
  -- remember what packages have been suggested
  -- to avoid spamming the user, if answering "No"
  -- when prompted if a package should be installed
  --
  INSERT INTO magicmake.suggested_packages
    (package)
  SELECT
    package
  FROM missing_package_names
  WHERE NOT EXISTS
  (
    SELECT 1 FROM magicmake.suggested_packages
    WHERE suggested_packages.package = missing_package_names.package
  )
  RETURNING package
)

SELECT
  string_agg(package,' ')
INTO
  _packages
FROM new_missing_packages;
--
-- return blank space separated list of packages
--
RETURN _packages;
END
$$;
