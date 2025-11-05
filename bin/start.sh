#!/bin/bash
set -e

# Verify DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL is not set!"
  exit 1
fi

# Run migrations
bundle exec rails db:migrate

# Start the server
exec bundle exec rails server -b 0.0.0.0 -p $PORT -e production

