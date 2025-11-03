#!/bin/bash
set -e

# Run migrations (ignore errors if already migrated)
echo "Running database migrations..."
bundle exec rails db:migrate || echo "Migrations completed or already up to date"

# Start the server
echo "Starting Rails server..."
exec bundle exec rails server -b 0.0.0.0 -p $PORT -e production

