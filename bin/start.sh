#!/bin/bash

# Verify DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL is not set!"
  exit 1
fi

# Run migrations (don't fail if they already ran)
bundle exec rails db:migrate || true

# Start the server
exec bundle exec rails server -b 0.0.0.0 -p $PORT -e production

