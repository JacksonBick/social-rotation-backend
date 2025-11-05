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

# Run migrations (don't fail if they already ran)
echo "Running database migrations..."
if bundle exec rails db:migrate 2>&1; then
  echo "Migrations completed successfully"
else
  echo "Migration command had issues, but continuing..."
fi

# Start the server
echo "Starting Rails server on port ${PORT:-8080}..."
exec bundle exec rails server -b 0.0.0.0 -p ${PORT:-8080} -e production

