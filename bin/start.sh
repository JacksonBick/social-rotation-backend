#!/bin/bash
set -e

# Verify DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL is not set!"
  exit 1
fi

echo "DATABASE_URL is set: ${DATABASE_URL:0:30}..."

# Run migrations - db:prepare creates database if needed, then runs migrations
echo "Setting up database..."
bundle exec rails db:prepare

# Verify migrations ran successfully by checking if users table exists
echo "Verifying database setup..."
bundle exec rails runner "ActiveRecord::Base.connection.table_exists?('users') ? puts('✓ Database tables created') : (puts('✗ ERROR: Database tables not created!'); exit 1)"

# Start the server
echo "Starting Rails server..."
exec bundle exec rails server -b 0.0.0.0 -p $PORT -e production

