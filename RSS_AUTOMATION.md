# RSS Feed Automation / Feedback Loop

## Overview
The RSS Feed Automation system provides a "set it and forget it" workflow for automatically detecting, pulling, and queuing content from RSS feeds for social media posting.

## Flow: Detect → Queue → Review → Post

### 1. **Detect** (Automatic Fetching)
- Background job (`RssFeedFetchJob`) automatically fetches new posts from all active RSS feeds
- Supports fetching individual feeds or all feeds at once
- Runs via scheduled tasks (cron) or manual trigger

### 2. **Queue** (Posts Database)
- All fetched posts are stored in the `rss_posts` table
- Posts are marked as "unviewed" by default
- Each post includes: title, description, content, image, URL, published date

### 3. **Review** (Optional)
- Users can browse RSS posts in the "RSS Feeds" section
- Filter by viewed/unviewed status
- Toggle posts between viewed/unviewed
- Bulk actions: mark all as viewed/unviewed

### 4. **Post** (Make Bucket)
- Users select posts and create buckets from RSS content
- Images from RSS posts are added to buckets
- Content can be edited before posting
- Scheduled to social media platforms

## Components

### Backend Components

#### 1. `RssFeedFetchJob` (Background Job)
```ruby
# Trigger for all feeds
RssFeedFetchJob.perform_later

# Trigger for specific feed
RssFeedFetchJob.perform_later(feed_id)
```

**Location:** `app/jobs/rss_feed_fetch_job.rb`

**Features:**
- Fetches all active RSS feeds
- Tracks success/failure for each feed
- Updates health status automatically
- Logs all activities

#### 2. `RssFetchService` (Service Layer)
**Location:** `app/services/rss_fetch_service.rb`

**Features:**
- Parses RSS, Atom, and RDF formats
- Extracts images, content, metadata
- Prevents duplicate posts
- Handles various feed structures

#### 3. API Endpoints

**POST `/api/v1/rss_feeds/fetch_all`**
- Triggers background job to fetch all active feeds
- Returns immediately (async processing)

**POST `/api/v1/rss_feeds/:id/fetch_posts`**
- Fetches posts for a specific feed
- Returns success/failure status

**POST `/api/v1/rss_feeds/validate`**
- Validates RSS feed URL before creating
- Returns preview of feed content

### Frontend Components

#### `RssFeeds.tsx`
- Manages RSS feed list
- "Fetch All Feeds" button triggers automation
- Shows feed health status
- Individual "Fetch Posts" buttons

#### `RssPosts.tsx`
- Displays posts from a feed
- View/unview toggle buttons
- Bulk selection and actions
- "Make Bucket" functionality

## Scheduling Automation

### Manual Trigger (Via Frontend)
1. Navigate to RSS Feeds page
2. Click "🔄 Fetch All Feeds" button
3. Background job starts fetching all active feeds

### Scheduled Automation (Via Cron)
Add to crontab for automatic fetching every 6 hours:

```bash
# Edit crontab
crontab -e

# Add this line (runs every 6 hours)
0 */6 * * * cd /path/to/app && rails rss:fetch_all
```

### Rake Tasks

**Fetch all feeds:**
```bash
rails rss:fetch_all
```

**Fetch specific feed:**
```bash
rails rss:fetch[feed_id]
```

**Check feed status:**
```bash
rails rss:status
```

## Health Monitoring

### Feed Health Status Levels
- **Healthy** (0-2 failures): Feed is working normally
- **Degraded** (3-4 failures): Feed experiencing intermittent issues
- **Broken** (5+ failures): Feed has persistent problems
- **Never Fetched**: Feed has not been fetched yet

### Health Tracking Fields
- `fetch_failure_count`: Number of consecutive failures
- `last_fetch_error`: Last error message encountered
- `last_successful_fetch_at`: Timestamp of last successful fetch
- `last_fetched_at`: Timestamp of last fetch attempt

## Usage Examples

### Adding a New RSS Feed
1. Click "Add RSS Feed" button
2. Enter feed URL (optionally validate first)
3. Provide name and description
4. Feed is created as "active"
5. Click "Fetch Posts" to immediately fetch content

### Automated Workflow
1. Set up RSS feeds for your content sources
2. Click "Fetch All Feeds" or set up cron job
3. Review unviewed posts in the feed
4. Select posts to create buckets
5. Edit images/content in buckets
6. Schedule posts to social media

### Bulk Operations
1. Use checkboxes to select multiple posts
2. Click "Mark All as Viewed" or "Mark All as Unviewed"
3. Posts are updated in bulk

## Benefits

✅ **Automated Content Discovery**: No manual checking for new posts  
✅ **Set It and Forget It**: Runs in background without user intervention  
✅ **Health Monitoring**: Automatically tracks feed reliability  
✅ **Bulk Processing**: Handle multiple feeds efficiently  
✅ **Review Before Posting**: Content is queued for review before publishing  
✅ **Scalable**: Can handle many RSS feeds simultaneously  

## Technical Notes

- Uses Rails ActiveJob for background processing
- Supports async job execution (Fire and Forget)
- All feeds are fetched independently (no blocking)
- Failed feeds are tracked but don't stop other feeds
- Posts are deduplicated by URL to prevent duplicates
- Feed health resets after successful fetch

