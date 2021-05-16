EXTENSION = magicmake
DATA = magicmake--1.0.sql

REGRESS = create_extension

SCRIPTS = magicmake

EXTRA_CLEAN = magicmake--1.0.sql

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

all: magicmake--1.0.sql

SQL_SRC = \
  header.sql \
	TABLES/import_apt_lists.sql \
	TABLES/file_packages.sql \
	TABLES/installed_packages.sql \
	TABLES/trace_files.sql \
	TABLES/trace_commands.sql \
	TABLES/missing_files.sql \
	TABLES/missing_dirs.sql \
	TABLES/suggested_packages.sql \
	FUNCTIONS/normalize_path.sql \
	FUNCTIONS/suggest_packages.sql \
	footer.sql

magicmake--1.0.sql: $(SQL_SRC)
	cat $^ > $@
