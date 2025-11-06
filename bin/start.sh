#!/bin/bash

# Verify DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL is not set!"
  exit 1
fi

echo "Starting Rails server..."
echo "DATABASE_URL: ${DATABASE_URL:0:50}..."
echo "PORT: ${PORT:-8080}"
echo "RAILS_ENV: ${RAILS_ENV:-production}"

# Run migrations - capture output to see what happens
echo "Running database migrations..."
MIGRATION_OUTPUT=$(bundle exec rails db:migrate 2>&1)
MIGRATION_EXIT=$?
echo "$MIGRATION_OUTPUT"
if [ $MIGRATION_EXIT -eq 0 ]; then
  echo "Migrations completed successfully"
else
  echo "Migration exit code: $MIGRATION_EXIT"
  echo "Attempting to continue anyway..."
fi

# Start the server
echo "Starting Rails server on port ${PORT:-8080}..."
exec bundle exec rails server -b 0.0.0.0 -p ${PORT:-8080} -e production

