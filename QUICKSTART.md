# Quick Start Guide - Social Rotation Rails API

## Setup

### 1. Install Dependencies
```bash
bundle install
```

### 2. Setup Database
```bash
# Create databases
rails db:create

# Run migrations
rails db:migrate

# (Optional) Seed data
rails db:seed
```

### 3. Run Tests
```bash
# Run all tests
bundle exec rspec

# Run model tests only
bundle exec rspec spec/models/

# Run controller tests only
bundle exec rspec spec/controllers/

# Run with documentation format
bundle exec rspec --format documentation
```

### 4. Start Server
```bash
rails server
```

The API will be available at `http://localhost:3000`

---

## Quick Test the API

### Using curl:

```bash
# Health check
curl http://localhost:3000/up

# Get buckets (requires auth)
curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://localhost:3000/api/v1/buckets

# Create bucket (requires auth)
curl -X POST \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"bucket":{"name":"Test Bucket","description":"My test bucket"}}' \
     http://localhost:3000/api/v1/buckets
```

---

## Project Structure

```
Rebrand-Social-rotation/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   └── api/v1/
│   │       ├── buckets_controller.rb
│   │       ├── scheduler_controller.rb
│   │       ├── user_info_controller.rb
│   │       ├── marketplace_controller.rb
│   │       └── bucket_schedules_controller.rb
│   └── models/
│       ├── user.rb
│       ├── bucket.rb
│       ├── image.rb
│       ├── video.rb
│       ├── bucket_image.rb
│       ├── bucket_schedule.rb
│       ├── bucket_send_history.rb
│       ├── market_item.rb
│       └── user_market_item.rb
├── config/
│   └── routes.rb (54 API endpoints)
├── db/
│   ├── migrate/ (10 migrations)
│   └── schema.rb
├── spec/
│   ├── models/ (9 model tests)
│   ├── controllers/ (6 controller tests)
│   └── factories/ (9 factories)
├── API_DOCUMENTATION.md
├── PROJECT_SUMMARY.md
└── QUICKSTART.md (this file)
```

---

## Key Files to Review

1. **API_DOCUMENTATION.md** - Complete API reference
2. **PROJECT_SUMMARY.md** - Detailed project summary
3. **config/routes.rb** - All API endpoints
4. **app/models/** - Business logic
5. **app/controllers/api/v1/** - API endpoints
6. **spec/** - All tests

---

## Common Commands

```bash
# Run console
rails console

# Run specific test
bundle exec rspec spec/models/user_spec.rb

# Check routes
rails routes | grep api

# Reset database
rails db:reset

# Check pending migrations
rails db:migrate:status

# Generate migration
rails generate migration AddColumnToTable

# Generate model
rails generate model ModelName

# Run linter
rubocop
```

---

## Testing Individual Components

### Test Models
```bash
# Test User model
bundle exec rspec spec/models/user_spec.rb -v

# Test Bucket model
bundle exec rspec spec/models/bucket_spec.rb -v

# Test specific test
bundle exec rspec spec/models/bucket_spec.rb:42
```

### Test Controllers
```bash
# Test Buckets controller
bundle exec rspec spec/controllers/api/v1/buckets_controller_spec.rb -v

# Test with seed from specific test
bundle exec rspec spec/controllers/api/v1/buckets_controller_spec.rb:15
```

---

## Using Rails Console

```ruby
# Start console
rails console

# Create a user
user = User.create!(name: 'Test User', email: 'test@example.com', password: 'password')

# Create a bucket
bucket = user.buckets.create!(name: 'My Bucket', description: 'Test bucket')

# Create an image
image = Image.create!(file_path: 'test.jpg', friendly_name: 'Test Image')

# Add image to bucket
bucket_image = bucket.bucket_images.create!(
  image: image, 
  friendly_name: 'Test Image',
  description: 'Test description'
)

# Create a schedule
schedule = bucket.bucket_schedules.create!(
  schedule: '0 9 * * 1-5',
  schedule_type: BucketSchedule::SCHEDULE_TYPE_ROTATION,
  post_to: BucketSchedule::BIT_FACEBOOK | BucketSchedule::BIT_TWITTER
)

# Query data
User.all
Bucket.count
BucketSchedule.where(schedule_type: 1)
```

---

## Environment Variables

Create a `.env` file in the root directory:

```env
# Database
DATABASE_URL=postgresql://localhost/rebrand_social_rotation_development

# API Keys (when implementing)
JWT_SECRET=your_jwt_secret_here
FACEBOOK_APP_ID=your_facebook_app_id
FACEBOOK_APP_SECRET=your_facebook_app_secret
TWITTER_API_KEY=your_twitter_api_key
TWITTER_API_SECRET=your_twitter_api_secret
LINKEDIN_CLIENT_ID=your_linkedin_client_id
LINKEDIN_CLIENT_SECRET=your_linkedin_client_secret
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret

# File Storage
AWS_ACCESS_KEY_ID=your_aws_key
AWS_SECRET_ACCESS_KEY=your_aws_secret
AWS_REGION=us-east-1
AWS_BUCKET=your-bucket-name

# Or for Digital Ocean
DO_SPACES_KEY=your_do_key
DO_SPACES_SECRET=your_do_secret
DO_SPACES_ENDPOINT=your_do_endpoint
DO_SPACES_BUCKET=your_bucket_name
```

---

## Database Schema Reference

### Key Tables
- `users` - User accounts (20+ columns including social media tokens)
- `buckets` - Content collections (6 columns)
- `images` - Image files (4 columns)
- `videos` - Video files (5 columns)
- `bucket_images` - Images in buckets (10 columns)
- `bucket_schedules` - Posting schedules (12 columns)
- `bucket_send_histories` - Send history (7 columns)
- `market_items` - Marketplace items (5 columns)
- `user_market_items` - Purchased items (4 columns)

### View Schema
```bash
rails db:schema:dump
cat db/schema.rb
```

---

## Troubleshooting

### Database Issues
```bash
# Drop and recreate database
rails db:drop db:create db:migrate

# Check database connection
rails dbconsole
```

### Test Issues
```bash
# Prepare test database
RAILS_ENV=test rails db:migrate

# Clear test database
RAILS_ENV=test rails db:reset
```

### Server Issues
```bash
# Kill existing server
lsof -ti:3000 | xargs kill -9

# Check running processes
ps aux | grep rails
```

---

## Next Steps

1. ✅ Review API_DOCUMENTATION.md for all endpoints
2. ✅ Review PROJECT_SUMMARY.md for complete overview
3. ⏳ Implement JWT authentication
4. ⏳ Add file storage integration
5. ⏳ Integrate social media APIs
6. ⏳ Set up background jobs
7. ⏳ Build React frontend

---

## Need Help?

- **API Docs**: See `API_DOCUMENTATION.md`
- **Project Summary**: See `PROJECT_SUMMARY.md`
- **Rails Docs**: https://guides.rubyonrails.org/
- **RSpec Docs**: https://rspec.info/
- **PostgreSQL Docs**: https://www.postgresql.org/docs/

---

## Quick Reference

### Social Media Bit Flags
```ruby
BIT_FACEBOOK = 1
BIT_TWITTER = 2
BIT_INSTAGRAM = 4
BIT_LINKEDIN = 8
BIT_GMB = 16
```

### Schedule Types
```ruby
SCHEDULE_TYPE_ROTATION = 1
SCHEDULE_TYPE_ONCE = 2
SCHEDULE_TYPE_ANNUALLY = 3
```

### Cron Examples
```ruby
'0 9 * * 1-5'  # 9 AM weekdays
'0 14 * * 6,0' # 2 PM weekends
'30 10 25 12 *' # 10:30 AM Dec 25
```

---

**Ready to start developing! 🚀**

