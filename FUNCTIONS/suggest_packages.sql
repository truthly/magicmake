CREATE OR REPLACE FUNCTION magicmake.suggest_packages(strace_log_dir text)
RETURNS SETOF text
LANGUAGE plpgsql
AS
$$
DECLARE
strace_log_file_path text;
BEGIN
FOR strace_log_file_path IN
SELECT pg_ls_dir(strace_log_dir)
LOOP
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
  FROM regexp_split_to_table(pg_read_file(strace_log_file_path),E'\n') AS log_line;
  --
  -- match the strace rows against file_packages
  --
  RETURN QUERY
  WITH
  missing_files AS
  (
    --
    -- guess missing files
    --
    SELECT
      file_name,
      array_agg(DISTINCT file_path) AS file_paths
    FROM magicmake.strace
    GROUP BY file_name
    HAVING bool_or(missing) AND NOT bool_or(NOT missing)
    UNION ALL
    --
    -- guess missing pkg_config packages
    --
    SELECT
      format('%s.pc', pkg_config_name) AS file_name,
      array_agg(DISTINCT format('%s%s.pc', pkg_config_path, pkg_config_name)) AS file_paths
    FROM
    (
      SELECT
        regexp_split_to_array(pkg_config_exec[1],', ') AS pkg_config_args,
        pkg_config_paths
      FROM
      (
        SELECT
          array_agg(exit_status) FILTER (WHERE exit_status IS NOT NULL) AS exit_statuses,
          array_agg(pkg_config) FILTER (WHERE pkg_config IS NOT NULL) AS pkg_config_exec,
          array_agg(DISTINCT LEFT(file_path,length(file_path)-length(file_name))) FILTER (WHERE file_name LIKE '%.pc') AS pkg_config_paths
        FROM magicmake.strace
      ) AS filter_agg_pkg_config
      WHERE
      --
      -- find pkg_config calls...
      --
        cardinality(pkg_config_exec) = 1
      AND
      --
      -- ...that exited with status 1...
      --
        exit_statuses = ARRAY[1]
      --
      -- ...possibly meaning a package was missing
      --
    ) AS pkg_config_rows
    CROSS JOIN unnest(pkg_config_paths) AS pkg_config_path
    CROSS JOIN unnest(pkg_config_args) AS pkg_config_arg_quoted
    JOIN btrim(pkg_config_arg_quoted,'"') AS pkg_config_arg
      ON pkg_config_arg ~ '^[^-][^-]?' -- ignore arguments that look like long options, e.g. --print-errors
    CROSS JOIN regexp_split_to_table(pkg_config_arg,' ') AS pkg_config_name
    GROUP BY 1
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
  extract_versions AS
  (
    SELECT
      package,
      file_paths,
      substring(package from '^(.*?)[.0-9-]*$') AS name_part,
      array_remove
      (
        regexp_split_to_array
        (
          regexp_replace
          (
            package,
            '[^0-9.-]+',
            '',
            'g'
          ),
          '[-.]'
        ),
        ''
      )::int[] AS version_part
    FROM missing_packages
  ),
  prioritize_versions AS
  (
    SELECT
      package,
      file_paths,
      ROW_NUMBER() OVER (
        PARTITION BY name_part
        --
        -- prefer packages with no explicit version
        -- which seems to usually be the latest version
        --
        ORDER BY cardinality(version_part) = 0 DESC,
        --
        -- otherwise, pick the one with the highest version
        --
        version_part DESC
      ) AS priority
    FROM extract_versions
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
    FROM prioritize_versions
    WHERE priority = 1
    AND NOT EXISTS
    (
      SELECT 1 FROM magicmake.suggested_packages
      WHERE suggested_packages.package = prioritize_versions.package
    )
    RETURNING package
  )
  SELECT
    package
  FROM suggest_new_packages;
END LOOP;
END
$$;
