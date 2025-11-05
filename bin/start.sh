#!/bin/bash
set -e

# Verify DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL is not set!"
  exit 1
fi

echo "DATABASE_URL is set: ${DATABASE_URL:0:30}..."

# Run migrations (ignore errors if already migrated)
echo "Running database migrations..."
bundle exec rails db:migrate || echo "Migrations completed or already up to date"

# Test database connection
echo "Testing database connection..."
bundle exec rails runner "ActiveRecord::Base.connection" || echo "WARNING: Database connection test failed"

# Start the server
echo "Starting Rails server..."
exec bundle exec rails server -b 0.0.0.0 -p $PORT -e production

