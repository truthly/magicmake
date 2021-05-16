CREATE OR REPLACE FUNCTION magicmake.hypothetical_file_paths()
RETURNS SETOF text
LANGUAGE plpgsql
AS
$_$
BEGIN
RETURN QUERY
WITH
missing_dir_candidates AS MATERIALIZED
(
  SELECT
    trace_files.file_path AS dir_path
  FROM magicmake.trace_files
  WHERE EXISTS
  (
    SELECT 1
    FROM magicmake.file_packages
    WHERE file_packages.dir_path = trace_files.file_path
  )
  AND NOT EXISTS
  (
    SELECT 1
    FROM magicmake.installed_packages
    JOIN magicmake.file_packages AS installed_files
      ON installed_files.package = installed_packages.package
    WHERE installed_files.dir_path = trace_files.file_path
  )
),
missing_dirs AS
(
  SELECT dir_path
  FROM missing_dir_candidates
  WHERE NOT EXISTS
  (
    SELECT 1
    FROM magicmake.installed_packages
    JOIN magicmake.file_packages AS installed_files
      ON installed_files.package = installed_packages.package
    WHERE installed_files.file_path LIKE (missing_dir_candidates.dir_path||'%')
  )
)
SELECT
  format('%s/%s',dir_path,file_name) AS hypothetical_file_path
FROM missing_dirs
CROSS JOIN
(
  SELECT DISTINCT
    substring(file_path from '[^/]+$') AS file_name
  FROM magicmake.trace_files
  WHERE file_path LIKE '%/%'
    AND file_path !~ '^(tmp|proc)/'
) AS file_names;
END
$_$;
