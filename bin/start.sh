#!/bin/bash
set -e

# Verify DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL is not set!"
  exit 1
fi

echo "DATABASE_URL is set: ${DATABASE_URL:0:30}..."

# Run migrations - for managed databases, just run migrations (db already exists)
echo "Running database migrations..."
bundle exec rails db:migrate || echo "WARNING: Migration command failed, continuing anyway..."

# Verify migrations ran successfully by checking if users table exists
echo "Verifying database setup..."
if bundle exec rails runner "puts ActiveRecord::Base.connection.table_exists?('users')" 2>/dev/null | grep -q "true"; then
  echo "✓ Database tables exist"
else
  echo "✗ WARNING: Users table not found - migrations may have failed"
  echo "Attempting to run migrations again..."
  bundle exec rails db:migrate
fi

# Start the server
echo "Starting Rails server..."
exec bundle exec rails server -b 0.0.0.0 -p $PORT -e production

