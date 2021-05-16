CREATE OR REPLACE FUNCTION magicmake.normalize_path(file_path text)
RETURNS text
LANGUAGE plpgsql
AS
$$
BEGIN
LOOP
  IF file_path ~ '[^/]+/\.\./' THEN
    file_path := regexp_replace(file_path, '[^/]+/\.\./', '', 'g');
  ELSE
    EXIT;
  END IF;
END LOOP;
RETURN file_path;
END
$$;
