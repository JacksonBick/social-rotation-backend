# Code Documentation - Pseudocode Explanations

This document explains what each model, controller, and test does in plain English pseudocode format.

---

## MODELS

### User Model (`app/models/user.rb`)
```
CLASS User
  PURPOSE: Represents user account with authentication, social media connections, watermark settings
  
  ASSOCIATIONS:
    - has_many buckets (destroy on delete)
    - has_many videos (destroy on delete)  
    - has_many user_market_items (destroy on delete)
    - has_many market_items through user_market_items
  
  VALIDATIONS:
    - email must exist, be unique, match email format
    - name must exist
    - password must exist (via has_secure_password)
  
  METHOD get_watermark_preview()
    RETURNS: '/user/standard_preview'
    PURPOSE: URL for watermark preview image
  
  METHOD get_relative_digital_ocean_watermark_path()
    RETURNS: "environment/user_id/watermarks/filename"
    PURPOSE: Relative path for cloud storage
  
  METHOD get_digital_ocean_watermark_path()
    IF watermark_logo exists
      RETURN full CDN URL with filename
    ELSE
      RETURN empty string
    PURPOSE: Full URL to watermark on Digital Ocean CDN
  
  METHOD get_watermark_logo()
    IF watermark_logo exists
      RETURN local storage path "/storage/env/id/watermarks/file"
    ELSE
      RETURN empty string
    PURPOSE: Local file path for watermark
  
  METHOD get_absolute_watermark_logo_directory()
    IF watermark_logo exists
      RETURN full filesystem path to watermark directory
    ELSE
      RETURN empty string
    PURPOSE: Absolute path for file operations
  
  METHOD get_absolute_watermark_scaled_logo_directory()
    IF watermark_logo exists
      RETURN full filesystem path to scaled watermarks directory
    ELSE
      RETURN empty string
    PURPOSE: Path to pre-processed watermark versions
  
  METHOD get_absolute_watermark_logo_path()
    IF watermark_logo exists
      RETURN full filesystem path to specific watermark file
    ELSE
      RETURN empty string
    PURPOSE: Direct file access path
END CLASS
```

### Bucket Model (`app/models/bucket.rb`)
```
CLASS Bucket
  PURPOSE: Collection of images/videos that can be scheduled for posting
  
  ASSOCIATIONS:
    - belongs_to user
    - has_many bucket_images (destroy on delete)
    - has_many images through bucket_images
    - has_many bucket_schedules (destroy on delete)
    - has_many bucket_send_histories (destroy on delete)
    - has_one market_item (destroy on delete)
  
  VALIDATIONS:
    - name must exist
  
  SCOPES:
    - is_market: WHERE account_id = 0 (marketplace buckets)
  
  METHOD is_market_bucket?()
    RETURNS: true if user.account_id == 0
    PURPOSE: Check if bucket is for sale in marketplace
  
  METHOD is_due(current_time)
    IF no schedules exist
      RETURN nil
    IF user has no timezone
      RETURN false
    
    FOR EACH schedule in bucket_schedules
      SKIP if schedule is '0 0 0 0 0'
      IF schedule format is valid
        IF schedule is due based on cron expression
          RETURN schedule
    RETURN nil
    PURPOSE: Check if any schedule is due to run now
  
  METHOD get_next_rotation_image(offset, skip_offset)
    ADD skip_offset to offset
    FIND all rotation-type schedules
    IF no rotation schedules
      RETURN nil
    
    GET last sent image from history
    GET all bucket images sorted by friendly_name
    
    IF history exists
      FIND image that was last sent
      IF image not found
        FIND next image by name or wrap to first
      
      CALCULATE next index in rotation
      APPLY offset (wrapping around if needed)
      RETURN image at calculated index
    ELSE (no history)
      IF offset > 0
        CALCULATE offset index (with wraparound)
        RETURN image at offset
      ELSE
        RETURN first image
    PURPOSE: Get next image in rotation sequence with offset support
END CLASS
```

### BucketSchedule Model (`app/models/bucket_schedule.rb`)
```
CLASS BucketSchedule
  PURPOSE: Defines when and where to post content (schedule + social networks)
  
  CONSTANTS:
    SCHEDULE_TYPE_ROTATION = 1    (post images in sequence)
    SCHEDULE_TYPE_ONCE = 2        (post once at specific time)
    SCHEDULE_TYPE_ANNUALLY = 3    (post once per year)
    
    BIT_FACEBOOK = 1              (bitwise flag for Facebook)
    BIT_TWITTER = 2               (bitwise flag for Twitter)
    BIT_INSTAGRAM = 4             (bitwise flag for Instagram)
    BIT_LINKEDIN = 8              (bitwise flag for LinkedIn)
    BIT_GMB = 16                  (bitwise flag for Google My Business)
    BIT_PINTEREST = 32            (bitwise flag for Pinterest)
    
    DEFAULT_TIME = '12:00'
    TWITTER_CHARACTER_LIMIT = 280
  
  ASSOCIATIONS:
    - belongs_to bucket
    - belongs_to bucket_image (optional)
    - has_many bucket_send_histories (destroy on delete)
  
  VALIDATIONS:
    - schedule must exist
    - schedule_type must be 1, 2, or 3
    - schedule must have 5 space-separated parts (cron format)
  
  METHOD get_next_schedule(offset)
    IF schedule_type is ONCE and already sent
      RETURN 'Already sent'
    IF schedule is valid cron format
      RETURN 'Next run calculated' (placeholder)
    ELSE
      RETURN 'Invalid Schedule'
    PURPOSE: Calculate next run time from cron expression
  
  METHOD get_type_image()
    IF ROTATION: RETURN 'rotation.png'
    IF ONCE: RETURN 'post_once.png'
    IF ANNUALLY: RETURN 'annual.png'
    PURPOSE: Get icon image for schedule type
  
  METHOD get_posts_to_images()
    FOR EACH social network (Facebook, Twitter, LinkedIn, Instagram, GMB)
      IF network bit is set in post_to
        SET icon to 'network_on.png'
      ELSE
        SET icon to 'network_off.png'
    RETURN hash of network => icon
    PURPOSE: Get on/off icons for each social network
  
  METHOD can_send?()
    GET most recent send history
    IF schedule_type is ANNUALLY
      IF no history: RETURN true
      IF last sent > 1 year ago: RETURN true
      ELSE: RETURN false
    ELSE
      RETURN true (rotation and once can always send)
    PURPOSE: Check if schedule is ready to send again
  
  METHOD get_next_bucket_image_due(offset, skip_offset)
    IF schedule_type is ONCE or ANNUALLY
      RETURN bucket_image (specific image)
    ELSE (rotation)
      RETURN bucket.get_next_rotation_image(offset, skip_offset)
    PURPOSE: Get image to post for this schedule
  
  METHOD should_display_twitter_warning?()
    IF ONCE or ANNUALLY schedule
      IF description > 280 chars AND no twitter_description AND posting to Twitter
        RETURN true
    
    IF ROTATION schedule AND posting to Twitter
      FOR EACH image in bucket
        IF image description > 280 chars AND no twitter_description
          RETURN true
    
    RETURN false
    PURPOSE: Warn if text is too long for Twitter
  
  METHOD get_next_description_due(offset, skip_offset, twitter_text)
    IF schedule_type is ONCE or ANNUALLY
      IF twitter_text requested
        RETURN schedule twitter_description OR image twitter_description
      ELSE
        RETURN schedule description OR image description
    ELSE (rotation)
      GET next image
      IF twitter_text requested
        RETURN image twitter_description
      ELSE
        RETURN image description
    PURPOSE: Get text description for next post
  
  CLASS METHOD get_network_hash()
    RETURN hash mapping BIT flags to icon filenames
    PURPOSE: Map network IDs to icons
  
  METHOD is_network_selected?(network_id)
    RETURN true if (post_to & network_id) > 0
    PURPOSE: Check if specific network is selected (bitwise AND)
  
  METHOD get_days_selected()
    PARSE schedule string
    EXTRACT 5th part (days of week)
    SPLIT by comma
    RETURN array of day numbers
    PURPOSE: Get which days schedule runs on
  
  METHOD is_day_selected?(day)
    GET days from schedule
    RETURN true if day is in list OR list contains '*'
    PURPOSE: Check if schedule runs on specific day
  
  METHOD get_time_format()
    PARSE schedule string
    EXTRACT hour and minute
    RETURN "hour:minute" format
    PURPOSE: Get human-readable time from cron
  
  METHOD get_scheduled_date_format()
    PARSE schedule string
    EXTRACT month and day
    RETURN "year-month-day" format
    PURPOSE: Get human-readable date from cron
  
  CLASS METHOD get_days_of_week_array()
    RETURN hash mapping 1-7 to day names
    PURPOSE: Convert day numbers to names
END CLASS
```

### BucketImage Model (`app/models/bucket_image.rb`)
```
CLASS BucketImage
  PURPOSE: Links an image to a bucket with custom description and settings
  
  ASSOCIATIONS:
    - belongs_to bucket
    - belongs_to image
    - has_many bucket_schedules
    - has_many bucket_send_histories
  
  VALIDATIONS:
    - friendly_name must exist
  
  METHOD forced_is_due?()
    IF no force_send_date: RETURN false
    IF user has no timezone: RETURN false
    
    CONVERT current time to user timezone
    CONVERT force_send_date to user timezone
    IF times match (year-month-day hour:minute)
      RETURN true
    ELSE
      RETURN false
    PURPOSE: Check if forced send time has arrived
  
  METHOD should_display_twitter_warning?()
    IF description > 280 chars AND no twitter_description
      RETURN true
    ELSE
      RETURN false
    PURPOSE: Warn if description too long for Twitter
END CLASS
```

### BucketSendHistory Model (`app/models/bucket_send_history.rb`)
```
CLASS BucketSendHistory
  PURPOSE: Records each social media post that was sent
  
  CONSTANTS:
    SENT_TO_FACEBOOK = 1 (example, uses BucketSchedule bit flags)
  
  ASSOCIATIONS:
    - belongs_to bucket
    - belongs_to bucket_schedule
    - belongs_to bucket_image
  
  METHOD get_sent_to_name()
    CREATE empty array
    IF sent_to includes Facebook bit: ADD 'Facebook'
    IF sent_to includes Twitter bit: ADD 'Twitter'
    IF sent_to includes LinkedIn bit: ADD 'LinkedIn'
    IF sent_to includes GMB bit: ADD 'Google My Business'
    IF sent_to includes Instagram bit: ADD 'Instagram'
    
    IF array empty: RETURN 'Unknown'
    ELSE: RETURN comma-separated list
    PURPOSE: Convert bit flags to human-readable platform names
END CLASS
```

### Image Model (`app/models/image.rb`)
```
CLASS Image
  PURPOSE: Centralized storage of image files (one file, many uses)
  
  ASSOCIATIONS:
    - has_many bucket_images
    - has_many buckets through bucket_images
    - has_many market_items
  
  VALIDATIONS:
    - file_path must exist
  
  METHOD get_source_url()
    RETURN "https://se1.sfo2.digitaloceanspaces.com/" + file_path
    PURPOSE: Get full CDN URL for image
END CLASS
```

### MarketItem Model (`app/models/market_item.rb`)
```
CLASS MarketItem
  PURPOSE: Represents content package for sale in marketplace
  
  ASSOCIATIONS:
    - belongs_to bucket
    - belongs_to front_image (optional)
    - has_many user_market_items
  
  VALIDATIONS:
    - price must exist and be >= 0
  
  SCOPES:
    - all_reseller: WHERE visible = true
  
  METHOD has_hidden_user_market_item?(user_id)
    RETURN true if user has purchased this item AND set visible=false
    PURPOSE: Check if user hid this purchased item
  
  METHOD has_user_market_item?(user_id)
    RETURN true if user has purchased this item
    PURPOSE: Check if user owns this item
  
  METHOD get_front_image_url()
    IF front_image exists: RETURN front_image URL
    IF bucket has images: RETURN first image URL
    ELSE: RETURN '/img/no_image_available.gif'
    PURPOSE: Get preview image for marketplace listing
  
  METHOD get_front_image_friendly_name()
    IF front_image exists: RETURN front_image name
    IF bucket has images: RETURN first image name
    ELSE: RETURN 'N/A'
    PURPOSE: Get name of preview image
END CLASS
```

### Video Model (`app/models/video.rb`)
```
CLASS Video
  PURPOSE: Stores video files with processing status
  
  CONSTANTS:
    STATUS_UNPROCESSED = 0
    STATUS_PROCESSING = 1
    STATUS_PROCESSED = 2
  
  ASSOCIATIONS:
    - belongs_to user
  
  VALIDATIONS:
    - file_path must exist
    - status must be 0, 1, or 2
  
  METHOD get_source_url()
    RETURN "https://se1.sfo2.digitaloceanspaces.com/" + file_path
    PURPOSE: Get full CDN URL for video
END CLASS
```

### UserMarketItem Model (`app/models/user_market_item.rb`)
```
CLASS UserMarketItem
  PURPOSE: Links user to purchased marketplace items
  
  ASSOCIATIONS:
    - belongs_to user
    - belongs_to market_item
  
  VALIDATIONS:
    - visible must be true or false
  
  PURPOSE: Track which users bought which items and if they're hidden
END CLASS
```

---

## CONTROLLERS

### BucketsController (`app/controllers/api/v1/buckets_controller.rb`)
```
CONTROLLER Api::V1::BucketsController
  PURPOSE: Manage content buckets (collections of images)
  
  BEFORE ACTIONS:
    - authenticate_user! (all actions)
    - set_bucket (show, update, destroy, page, randomize, images, single_image)
    - set_bucket_for_image_actions (update_image, delete_image)
    - set_bucket_image (update_image, delete_image)
  
  ACTION index()
    GET all buckets for current user with bucket_images and bucket_schedules
    RENDER JSON with array of bucket objects
    PURPOSE: List user's buckets
  
  ACTION show(id)
    GET bucket with images and schedules
    RENDER JSON with bucket, images array, schedules array
    PURPOSE: Get detailed bucket info
  
  ACTION create(bucket_params)
    CREATE new bucket for current user
    IF save successful
      RENDER created status with bucket JSON
    ELSE
      RENDER unprocessable_entity with errors
    PURPOSE: Create new bucket
  
  ACTION update(id, bucket_params)
    UPDATE bucket with params
    IF save successful
      RENDER bucket JSON
    ELSE
      RENDER unprocessable_entity with errors
    PURPOSE: Update bucket details
  
  ACTION destroy(id)
    DELETE bucket
    RENDER success message
    PURPOSE: Delete bucket and all associated data
  
  ACTION page(id, page_num)
    CALCULATE skip = (page_num - 1) * 12 images
    GET bucket_images with offset and limit
    RENDER JSON with images array and pagination info
    PURPOSE: Get paginated bucket images (12 per page, 4x3 grid)
  
  ACTION images(id)
    GET all bucket_images sorted by friendly_name
    RENDER JSON with images array
    PURPOSE: Get all images in bucket
  
  ACTION update_image(id, image_id, params)
    UPDATE bucket_image with params
    IF save successful
      RENDER image JSON
    ELSE
      RENDER unprocessable_entity with errors
    PURPOSE: Update image description, watermark settings, etc.
  
  ACTION delete_image(id, image_id)
    DELETE associated schedules first
    DELETE bucket_image
    RENDER success message
    PURPOSE: Remove image from bucket
  
  ACTION randomize(id)
    GET all bucket_images
    SHUFFLE friendly_names array
    ASSIGN shuffled names to images
    RENDER success message
    PURPOSE: Randomize image order in bucket
  
  ACTION for_scheduling(ignore_post_now)
    IF ignore_post_now
      GET buckets WHERE post_once_bucket = false
    ELSE
      GET all buckets
    RENDER JSON with buckets array
    PURPOSE: Get buckets available for scheduling
END CONTROLLER
```

### BucketSchedulesController (`app/controllers/api/v1/bucket_schedules_controller.rb`)
```
CONTROLLER Api::V1::BucketSchedulesController
  PURPOSE: Manage posting schedules for buckets
  
  BEFORE ACTIONS:
    - authenticate_user! (all actions)
    - set_bucket_schedule (show, update, destroy, post_now, skip_image, skip_image_single, history)
  
  ACTION index()
    GET all bucket_schedules for current user with bucket and bucket_image
    RENDER JSON with schedules array
    PURPOSE: List all user's schedules
  
  ACTION show(id)
    RENDER JSON with schedule details
    PURPOSE: Get single schedule
  
  ACTION create(bucket_id, params)
    FIND bucket
    CREATE schedule for bucket
    IF save successful
      RENDER created status with schedule JSON
    ELSE
      RENDER unprocessable_entity with errors
    PURPOSE: Create new schedule
  
  ACTION update(id, params)
    UPDATE schedule with params
    IF save successful
      RENDER schedule JSON
    ELSE
      RENDER unprocessable_entity with errors
    PURPOSE: Update schedule details
  
  ACTION destroy(id)
    DELETE schedule
    RENDER success message
    PURPOSE: Delete schedule
  
  ACTION bulk_update(schedule_ids, networks, time)
    PARSE time string
    CALCULATE post_to flags from networks
    CREATE cron string from time
    FOR EACH schedule_id
      FIND schedule
      UPDATE schedule and post_to
    RENDER success message with count
    PURPOSE: Update multiple schedules at once
  
  ACTION bulk_delete(schedule_ids)
    FOR EACH schedule_id
      FIND schedule
      DELETE schedule
    RENDER success message with count
    PURPOSE: Delete multiple schedules at once
  
  ACTION rotation_create(bucket_id, networks, time, days)
    FIND bucket
    CALCULATE post_to flags from networks
    PARSE time (remove leading zeros)
    CREATE cron string: "minute hour * * days"
    CREATE rotation schedule
    RENDER created status with schedule JSON
    PURPOSE: Create rotation schedule (cycles through images on specific days/time)
  
  ACTION date_create(bucket_id, bucket_image_id, networks, time, post_annually)
    FIND bucket and image
    CALCULATE post_to flags from networks
    PARSE time
    CREATE cron string
    IF post_annually
      CREATE annually schedule
    ELSE
      CREATE once schedule
    RENDER created status with schedule JSON
    PURPOSE: Create date-specific schedule (once or annually)
  
  ACTION post_now(id)
    INCREMENT times_sent counter
    RENDER success message
    PURPOSE: Mark schedule as executed immediately
  
  ACTION skip_image(id)
    INCREMENT skip_image counter
    RENDER success message
    PURPOSE: Skip one image in rotation
  
  ACTION skip_image_single(id)
    IF annually schedule
      SET skip_image = 1
    IF once schedule
      DELETE schedule
    RENDER success message
    PURPOSE: Skip this scheduled post
  
  ACTION history(id)
    GET all bucket_send_histories for schedule
    RENDER JSON with schedule and history array
    PURPOSE: Get posting history for schedule
END CONTROLLER
```

### SchedulerController (`app/controllers/api/v1/scheduler_controller.rb`)
```
CONTROLLER Api::V1::SchedulerController
  PURPOSE: Handle immediate posting and single posts
  
  BEFORE ACTIONS:
    - authenticate_user! (all actions)
    - set_bucket_schedule (post_now, skip_image, skip_image_single)
  
  ACTION single_post(networks, caption, file, existing_image_id, link, post_date)
    CALCULATE post_to flags from networks
    
    IF file uploaded
      CREATE image record
      CREATE or find post-once bucket
      CREATE bucket_image
    ELSE IF existing_image_id provided
      FIND bucket_image
    ELSE IF link provided
      HANDLE link sharing (placeholder)
    ELSE
      RETURN error "no content"
    
    IF post_date provided
      CREATE once schedule for future date
    ELSE
      POST immediately (placeholder)
    
    RENDER success message
    PURPOSE: Post single image/link to social media
  
  ACTION schedule(bucket_id, networks, time, days)
    CREATE rotation schedule
    (Same as rotation_create in BucketSchedulesController)
    PURPOSE: Create rotation schedule
  
  ACTION post_now(id)
    INCREMENT times_sent
    RENDER success message
    PURPOSE: Execute schedule immediately
  
  ACTION skip_image(id)
    INCREMENT skip_image counter
    RENDER success message
    PURPOSE: Skip one image
  
  ACTION skip_image_single(id)
    IF annually: SET skip_image = 1
    IF once: DELETE schedule
    RENDER success message
    PURPOSE: Skip single scheduled post
  
  ACTION open_graph(url)
    FETCH open graph data from URL (placeholder)
    RENDER JSON with OG data
    PURPOSE: Get link preview data
END CONTROLLER
```

### UserInfoController (`app/controllers/api/v1/user_info_controller.rb`)
```
CONTROLLER Api::V1::UserInfoController
  PURPOSE: Manage user profile and social media connections
  
  BEFORE ACTIONS:
    - authenticate_user! (all actions)
  
  ACTION show()
    RENDER JSON with user data and connected_accounts array
    PURPOSE: Get user profile
  
  ACTION update(user_params)
    UPDATE current_user with params
    IF save successful
      RENDER user JSON
    ELSE
      RENDER unprocessable_entity with errors
    PURPOSE: Update user profile
  
  ACTION update_watermark(watermark_params, logo_file)
    IF logo_file uploaded
      SAVE watermark file (placeholder)
    UPDATE user watermark settings
    RENDER user JSON
    PURPOSE: Update watermark settings
  
  ACTION connected_accounts()
    RENDER JSON with array of connected social networks
    PURPOSE: Get list of connected accounts
  
  ACTION disconnect_facebook()
    SET fb_user_access_key = nil
    SET instagram_business_id = nil
    RENDER success message
    PURPOSE: Disconnect Facebook/Instagram
  
  ACTION disconnect_twitter()
    SET all twitter fields to nil
    RENDER success message
    PURPOSE: Disconnect Twitter
  
  ACTION disconnect_linkedin()
    SET all linkedin fields to nil
    RENDER success message
    PURPOSE: Disconnect LinkedIn
  
  ACTION disconnect_google()
    SET google_refresh_token = nil
    SET location_id = nil
    RENDER success message
    PURPOSE: Disconnect Google My Business
  
  ACTION toggle_instagram()
    TOGGLE post_to_instagram boolean
    RENDER success message
    PURPOSE: Enable/disable Instagram posting
  
  ACTION watermark_preview()
    RENDER JSON with preview_url
    PURPOSE: Get watermark preview image
  
  ACTION standard_preview()
    RENDER JSON with preview_url
    PURPOSE: Get standard watermark preview
END CONTROLLER
```

### MarketplaceController (`app/controllers/api/v1/marketplace_controller.rb`)
```
CONTROLLER Api::V1::MarketplaceController
  PURPOSE: Manage content marketplace (buy/sell buckets)
  
  BEFORE ACTIONS:
    - authenticate_user! (all actions)
    - set_market_item (show, info, clone, copy_to_bucket, buy, hide, make_visible)
  
  ACTION index()
    GET user's purchased market_items WHERE visible = true
    RENDER JSON with market_items array
    PURPOSE: List user's purchased items
  
  ACTION available()
    GET all visible market_items user hasn't purchased
    RENDER JSON with available_items array
    PURPOSE: List items available for purchase
  
  ACTION show(id)
    GET market_item with first 12 bucket_images
    RENDER JSON with item and images
    PURPOSE: Get marketplace item details with preview images
  
  ACTION info(id)
    GET market_item with first 4 bucket_images
    RENDER JSON with item and preview_images
    PURPOSE: Get quick preview of item
  
  ACTION clone(id, preserve_scheduling)
    CREATE new bucket copying name and settings
    FOR EACH image in market_item bucket
      CREATE new bucket_image copying all fields
      IF preserve_scheduling
        CREATE schedules for images with force_send_date
    RENDER JSON with new bucket
    PURPOSE: Copy marketplace item to user's buckets
  
  ACTION copy_to_bucket(id, target_bucket_id)
    FIND target bucket
    FOR EACH image in market_item bucket
      CREATE new bucket_image in target bucket
    RENDER success message
    PURPOSE: Add marketplace images to existing bucket
  
  ACTION buy(id)
    CREATE user_market_item record
    (Would integrate with payment processing)
    RENDER success message
    PURPOSE: Purchase marketplace item
  
  ACTION hide(id)
    FIND user_market_item
    SET visible = false
    RENDER success message
    PURPOSE: Hide purchased item from list
  
  ACTION make_visible(id)
    FIND user_market_item
    SET visible = true
    RENDER success message
    PURPOSE: Unhide purchased item
  
  ACTION user_buckets()
    GET all buckets for current user
    RENDER JSON with buckets array
    PURPOSE: Get user's buckets (for copy_to_bucket action)
END CONTROLLER
```

---

## TESTS

### Model Tests (`spec/models/*_spec.rb`)
```
Each model test follows this pattern:

TEST User Model
  TEST associations
    - Should have_many buckets (dependent destroy)
    - Should have_many videos (dependent destroy)
    - Should have_many user_market_items (dependent destroy)
  
  TEST validations
    - Should validate_presence_of email
    - Should validate_presence_of name
    - Should validate_uniqueness_of email
  
  TEST password security
    - CREATE user with password
    - VERIFY authenticate works with correct password
    - VERIFY authenticate fails with wrong password
  
  TEST watermark methods
    - CREATE user with watermark_logo
    - VERIFY all path methods return correct URLs
    - SET watermark_logo to nil
    - VERIFY methods return empty strings

(Similar pattern for Bucket, BucketSchedule, BucketImage, etc.)
```

### Controller Tests (`spec/controllers/api/v1/*_spec.rb`)
```
Each controller test follows this pattern:

TEST BucketsController
  BEFORE each test
    - MOCK authenticate_user!
    - MOCK current_user
    - CREATE test user and buckets
  
  TEST GET index
    - CREATE 3 buckets (2 for user, 1 for other user)
    - CALL GET /api/v1/buckets
    - VERIFY response is 200 OK
    - VERIFY returns 2 buckets (not other user's)
  
  TEST POST create
    - CALL POST /api/v1/buckets with valid params
    - VERIFY response is 201 Created
    - VERIFY bucket was created in database
    - VERIFY response includes bucket JSON
  
  TEST POST create with invalid params
    - CALL POST /api/v1/buckets with blank name
    - VERIFY response is 422 Unprocessable Entity
    - VERIFY response includes error messages
  
  TEST DELETE destroy
    - CREATE bucket
    - CALL DELETE /api/v1/buckets/:id
    - VERIFY response is 200 OK
    - VERIFY bucket was deleted from database

(Similar pattern for BucketSchedules, Scheduler, UserInfo, Marketplace)
```

---

## KEY PATTERNS

### Bitwise Flags for Social Networks
```
CONCEPT: Use single integer to store multiple boolean values

BIT_FACEBOOK = 1   (binary: 00001)
BIT_TWITTER = 2    (binary: 00010)
BIT_INSTAGRAM = 4  (binary: 00100)
BIT_LINKEDIN = 8   (binary: 01000)
BIT_GMB = 16       (binary: 10000)

TO SET: post_to = post_to | BIT_FACEBOOK (adds Facebook)
TO CHECK: (post_to & BIT_FACEBOOK) > 0 (checks if Facebook included)
TO UNSET: post_to = post_to & ~BIT_FACEBOOK (removes Facebook)

EXAMPLE:
  post_to = 0
  post_to |= BIT_FACEBOOK  # post_to = 1 (Facebook only)
  post_to |= BIT_TWITTER   # post_to = 3 (Facebook + Twitter)
  (post_to & BIT_FACEBOOK) > 0  # true (includes Facebook)
  (post_to & BIT_INSTAGRAM) > 0 # false (no Instagram)
```

### Cron Schedule Format
```
CONCEPT: Unix cron format for scheduling

FORMAT: "minute hour day month weekday"

EXAMPLES:
  "0 9 * * 1,2,3,4,5"  = 9:00 AM on weekdays
  "30 14 15 * *"       = 2:30 PM on 15th of every month
  "0 12 * * *"         = 12:00 PM every day
  "0 0 1 1 *"          = midnight on January 1st

PARSING:
  parts = schedule.split(' ')
  minute = parts[0]
  hour = parts[1]
  day = parts[2]
  month = parts[3]
  weekday = parts[4]
```

### Image Rotation Logic
```
CONCEPT: Cycle through images in order, track last sent

STEP 1: Get all images sorted by friendly_name
STEP 2: Find last sent image from history
STEP 3: Calculate next index = (current_index + 1) % total_images
STEP 4: Apply offset if needed
STEP 5: Return image at calculated index

EXAMPLE with 4 images (A, B, C, D):
  Last sent: B (index 1)
  Next index: (1 + 1) % 4 = 2
  Next image: C
  
  With offset = 2:
  Start index: 2 (from above)
  After offset: (2 + 2) % 4 = 0
  Final image: A (wraps around)
```

### JSON Response Format
```
CONCEPT: Consistent JSON structure for all endpoints

SUCCESS RESPONSE:
{
  "bucket": { ...bucket data... },
  "message": "Bucket created successfully"
}

ERROR RESPONSE:
{
  "errors": ["Name can't be blank", "Schedule invalid"]
}

LIST RESPONSE:
{
  "buckets": [
    { id: 1, name: "Bucket 1", ... },
    { id: 2, name: "Bucket 2", ... }
  ]
}

NESTED RESPONSE:
{
  "bucket": { id: 1, name: "Bucket 1" },
  "images": [...array of images...],
  "schedules": [...array of schedules...]
}
```

---

This documentation provides pseudocode explanations for every model, controller, and test in the application. Use it as a reference to understand what each piece of code does without reading through the actual implementation.

