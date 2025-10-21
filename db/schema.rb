# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_10_20_160005) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bucket_images", force: :cascade do |t|
    t.bigint "bucket_id", null: false
    t.bigint "image_id", null: false
    t.string "friendly_name"
    t.text "description"
    t.text "twitter_description"
    t.datetime "force_send_date"
    t.boolean "repeat"
    t.integer "post_to"
    t.boolean "use_watermark"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bucket_id"], name: "index_bucket_images_on_bucket_id"
    t.index ["image_id"], name: "index_bucket_images_on_image_id"
  end

  create_table "bucket_schedules", force: :cascade do |t|
    t.bigint "bucket_id", null: false
    t.bigint "bucket_image_id"
    t.string "schedule"
    t.datetime "schedule_time"
    t.integer "post_to"
    t.integer "schedule_type"
    t.text "description"
    t.text "twitter_description"
    t.integer "times_sent"
    t.integer "skip_image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bucket_id"], name: "index_bucket_schedules_on_bucket_id"
    t.index ["bucket_image_id"], name: "index_bucket_schedules_on_bucket_image_id"
  end

  create_table "bucket_send_histories", force: :cascade do |t|
    t.bigint "bucket_id", null: false
    t.bigint "bucket_schedule_id", null: false
    t.bigint "bucket_image_id", null: false
    t.string "friendly_name"
    t.text "text"
    t.text "twitter_text"
    t.integer "sent_to"
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bucket_id"], name: "index_bucket_send_histories_on_bucket_id"
    t.index ["bucket_image_id"], name: "index_bucket_send_histories_on_bucket_image_id"
    t.index ["bucket_schedule_id"], name: "index_bucket_send_histories_on_bucket_schedule_id"
  end

  create_table "buckets", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.bigint "user_id", null: false
    t.integer "account_id"
    t.boolean "use_watermark"
    t.boolean "post_once_bucket"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_buckets_on_user_id"
  end

  create_table "images", force: :cascade do |t|
    t.string "file_path"
    t.string "friendly_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "market_items", force: :cascade do |t|
    t.bigint "bucket_id", null: false
    t.bigint "front_image_id"
    t.decimal "price"
    t.boolean "visible"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bucket_id"], name: "index_market_items_on_bucket_id"
    t.index ["front_image_id"], name: "index_market_items_on_front_image_id"
  end

  create_table "user_market_items", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "market_item_id", null: false
    t.boolean "visible"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["market_item_id"], name: "index_user_market_items_on_market_item_id"
    t.index ["user_id"], name: "index_user_market_items_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.string "name"
    t.string "timezone"
    t.string "watermark_logo"
    t.decimal "watermark_scale"
    t.integer "watermark_opacity"
    t.integer "watermark_offset_x"
    t.integer "watermark_offset_y"
    t.integer "account_id"
    t.text "fb_user_access_key"
    t.string "instagram_business_id"
    t.text "twitter_oauth_token"
    t.text "twitter_oauth_token_secret"
    t.string "twitter_user_id"
    t.string "twitter_screen_name"
    t.text "linkedin_access_token"
    t.datetime "linkedin_access_token_time"
    t.string "linkedin_profile_id"
    t.text "google_refresh_token"
    t.string "location_id"
    t.boolean "post_to_instagram"
    t.string "twitter_url_oauth_token"
    t.string "twitter_url_oauth_token_secret"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tiktok_access_token"
    t.string "tiktok_refresh_token"
    t.string "tiktok_user_id"
    t.string "tiktok_username"
    t.string "youtube_access_token"
    t.string "youtube_refresh_token"
    t.string "youtube_channel_id"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "videos", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "file_path"
    t.string "friendly_name"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_videos_on_user_id"
  end

  add_foreign_key "bucket_images", "buckets"
  add_foreign_key "bucket_images", "images"
  add_foreign_key "bucket_schedules", "bucket_images"
  add_foreign_key "bucket_schedules", "buckets"
  add_foreign_key "bucket_send_histories", "bucket_images"
  add_foreign_key "bucket_send_histories", "bucket_schedules"
  add_foreign_key "bucket_send_histories", "buckets"
  add_foreign_key "buckets", "users"
  add_foreign_key "market_items", "buckets"
  add_foreign_key "market_items", "images", column: "front_image_id"
  add_foreign_key "user_market_items", "market_items"
  add_foreign_key "user_market_items", "users"
  add_foreign_key "videos", "users"
end
