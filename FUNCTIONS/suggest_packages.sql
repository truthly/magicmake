CREATE OR REPLACE FUNCTION magicmake.suggest_packages(strace_log_file_path text)
RETURNS SETOF text
LANGUAGE plpgsql
AS
$$
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
  (log_line)
SELECT
  log_line
FROM regexp_split_to_table(pg_read_file(strace_log_file_path),E'\n') AS log_line
WHERE log_line ~ '^(?:\d+ +)?[a-z]+\(';
--
-- match the strace rows against file_packages
--
RETURN QUERY
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
    regexp_replace
    (
      --
      -- ignore multiple packages separated by comma,
      -- just pick the first one
      --
      regexp_replace(file_packages.packages,',.*$',''),
      --
      -- extract the package name
      --
      '^.*?([^/]+)$',
      '\1'
    ) AS package,
    array_agg(file_packages.file_path) AS file_paths
  FROM missing_files
  JOIN magicmake.file_packages
    ON file_packages.file_name = missing_files.file_name
  AND file_packages.file_path = ANY(missing_files.file_paths)
  GROUP BY 1
),
new_missing_packages AS
(
  --
  -- remember what packages have been suggested
  -- to avoid spamming the user, if answering "No"
  -- when prompted if a package should be installed
  --
  INSERT INTO magicmake.suggested_packages
    (package, file_paths)
  SELECT
    package, file_paths
  FROM missing_packages
  WHERE NOT EXISTS
  (
    SELECT 1 FROM magicmake.suggested_packages
    WHERE suggested_packages.package = missing_packages.package
  )
  RETURNING package
)
SELECT
  package
FROM new_missing_packages;
END
$$;
