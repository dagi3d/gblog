-- Add migration script here
CREATE TABLE posts (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT NOT NULL,
  status VARCHAR(256) NOT NULL,
  path VARCHAR(256) NOT NULL,
  excerpt TEXT NOT NULL,
  content TEXT NOT NULL,
  tags TEXT NOT NULL DEFAULT '',
  published_at DATE NOT NULL
)
