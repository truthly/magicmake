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
	TABLES/file_packages.sql \
	TABLES/strace.sql \
	TABLES/suggested_packages.sql \
	FUNCTIONS/suggest_packages.sql \
	footer.sql

magicmake--1.0.sql: $(SQL_SRC)
	cat $^ > $@
