CREATE TABLE magicmake.suggested_packages (
package text NOT NULL,
file_paths text[] NOT NULL,
suggested_at timestamptz NOT NULL DEFAULT now(),
PRIMARY KEY (package)
);
