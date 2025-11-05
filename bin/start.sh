#!/bin/bash

# Verify DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL is not set!"
  exit 1
fi

echo "=========================================="
echo "Starting Social Rotation Backend"
echo "=========================================="
echo "DATABASE_URL is set: ${DATABASE_URL:0:50}..."
echo "RAILS_ENV: ${RAILS_ENV:-not set}"
echo "PORT: ${PORT:-not set}"
echo ""

# Run migrations - for managed databases, just run migrations (db already exists)
echo "=========================================="
echo "Step 1: Running database migrations..."
echo "=========================================="
if bundle exec rails db:migrate 2>&1; then
  echo "✓ Migrations completed successfully"
else
  echo "✗ Migration command returned non-zero exit code"
  echo "Attempting to continue anyway..."
fi
echo ""

# Verify migrations ran successfully by checking if users table exists
echo "=========================================="
echo "Step 2: Verifying database setup..."
echo "=========================================="
TABLE_CHECK=$(bundle exec rails runner "puts ActiveRecord::Base.connection.table_exists?('users')" 2>&1)
echo "Table check output: $TABLE_CHECK"

if echo "$TABLE_CHECK" | grep -q "true"; then
  echo "✓ Database tables exist - users table found"
else
  echo "✗ WARNING: Users table not found!"
  echo "Attempting to run migrations again..."
  bundle exec rails db:migrate 2>&1
  echo ""
  echo "Re-checking users table..."
  TABLE_CHECK2=$(bundle exec rails runner "puts ActiveRecord::Base.connection.table_exists?('users')" 2>&1)
  if echo "$TABLE_CHECK2" | grep -q "true"; then
    echo "✓ Users table now exists after retry"
  else
    echo "✗ ERROR: Users table still not found after migration retry"
    echo "Table check output: $TABLE_CHECK2"
  fi
fi
echo ""

# Start the server
echo "=========================================="
echo "Step 3: Starting Rails server..."
echo "=========================================="
echo "Server will listen on 0.0.0.0:${PORT:-8080}"
echo "=========================================="
exec bundle exec rails server -b 0.0.0.0 -p ${PORT:-8080} -e production

