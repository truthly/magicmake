CREATE OR REPLACE FUNCTION magicmake.suggest_packages()
RETURNS SETOF text
LANGUAGE plpgsql
AS
$_$
BEGIN
--
-- match the trace_files rows against file_packages
--
RETURN QUERY
WITH
missing_packages AS
(
  SELECT
    file_packages.package,
    array_agg(file_packages.file_path) AS file_paths
  FROM magicmake.trace_files
  JOIN magicmake.file_packages
    ON file_packages.file_path = trace_files.file_path
  WHERE NOT EXISTS
  (
    SELECT 1
    FROM magicmake.installed_packages
    JOIN magicmake.file_packages AS installed_files
      ON installed_files.package = installed_packages.package
    WHERE installed_files.file_path = file_packages.file_path
  )
  GROUP BY file_packages.package
),
suggest_new_packages AS
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
  string_agg(package,',')
FROM
(
  SELECT
    a.package,
    MIN(b.package) AS conflict_group
  FROM (
    SELECT array_agg(package) FROM suggest_new_packages
  ) AS q1
  JOIN file_packages AS a ON a.package = ANY(q1.array_agg)
  JOIN file_packages AS b ON b.package = ANY(q1.array_agg) AND a.file_path = b.file_path
  GROUP BY a.package
) AS q2
GROUP BY conflict_group;
RETURN;
END
$_$;

CREATE OR REPLACE FUNCTION magicmake.suggest_packages(trace_files_log text, trace_commands_log text)
RETURNS SETOF text
LANGUAGE plpgsql
AS
$_$
DECLARE
_packages text[];
BEGIN
--
-- truncate before importing
--
TRUNCATE magicmake.trace_files, magicmake.trace_commands;
--
-- parse the /usr/sbin/trace-bpfcc output by splitting at newlines
-- and filtering out lines that looks like syscalls
--
INSERT INTO magicmake.trace_files
  (file_path)
SELECT DISTINCT
  normalize_path
FROM
(
  SELECT
    magicmake.normalize_path(trimmed)
  FROM
  (
    SELECT
      regexp_replace(btrim(unquoted,'/'),'/+','/','g') AS trimmed
    FROM
    (
      SELECT
        COALESCE(single_quoted,double_quoted) AS unquoted
      FROM
      (
        SELECT
          regexp_replace(regexp_match[1],'\\(.)','\1','g') AS single_quoted,
          regexp_match[2] AS double_quoted
        FROM
        (
          SELECT
            regexp_match(log_line,$regex$file_name=b(?:'(.*)'|"(.*)")$$regex$)
          FROM regexp_split_to_table(pg_read_file(trace_files_log),E'\n') AS log_line
        ) AS q1
        WHERE regexp_match IS NOT NULL
      ) AS q2
    ) AS q3
    WHERE unquoted LIKE '/%'
  ) AS q4
  WHERE trimmed <> ''
) AS q5
;
--
-- parse the /usr/sbin/execsnoop-bpfcc output
--
INSERT INTO magicmake.trace_commands
  (cmd_args)
SELECT DISTINCT
  right(cmd_args,-35)
FROM regexp_split_to_table(pg_read_file(trace_commands_log),E'\n') AS cmd_args
;
--
-- generate hypothetical file paths for possibly missing pkg-config packages
-- by computing the cartesian product between all pkg-config arguments
-- times all pkg-config paths possibly containing .pc files
--
-- this is necessary as pkg-config doesn't look for the specific .pc file
-- for the passed argument, but instead does a full scan of each directory
-- and then internally compares the filenames in such directories
-- with the arguments, to determine if it's missing or not
--
INSERT INTO magicmake.trace_files
  (file_path)
SELECT
  file_path
FROM
(
  SELECT
    format('%s%s.pc',pkg_config_dirs.dir,pkg_config_args.arg) AS file_path
  FROM
  (
    SELECT DISTINCT
      regexp_split_to_table(regexp_replace(cmd_args,'^/usr/bin/pkg-config ',''),' ') AS arg
    FROM magicmake.trace_commands
    WHERE cmd_args LIKE '/usr/bin/pkg-config %'
  ) AS pkg_config_args
  CROSS JOIN
  (
    SELECT DISTINCT
      substring(file_path from '^(.*/)[^/]+\.pc$') AS dir
    FROM magicmake.trace_files
    WHERE file_path LIKE '%.pc'
  ) AS pkg_config_dirs
  WHERE pkg_config_args.arg NOT LIKE '--%'
) AS pkg_config_files
WHERE NOT EXISTS
(
  SELECT 1 FROM magicmake.trace_files
  WHERE trace_files.file_path = pkg_config_files.file_path
)
;

RETURN QUERY
SELECT magicmake.suggest_packages();
IF NOT FOUND THEN
  INSERT INTO magicmake.trace_files
    (file_path)
  SELECT * FROM magicmake.hypothetical_file_paths()
  WHERE NOT EXISTS
  (
    SELECT 1 FROM magicmake.trace_files
    WHERE trace_files.file_path = hypothetical_file_paths
  );
  RETURN QUERY
  SELECT magicmake.suggest_packages();
END IF;

RETURN;
END
$_$;
