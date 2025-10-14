class Api::V1::BucketsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bucket, only: [:show, :update, :destroy, :page, :randomize, :images, :single_image, :upload_image]
  before_action :set_bucket_for_image_actions, only: [:update_image, :delete_image]
  before_action :set_bucket_image, only: [:update_image, :delete_image]

  # GET /api/v1/buckets
  def index
    @buckets = current_user.buckets.includes(:bucket_images, :bucket_schedules)
    render json: {
      buckets: @buckets.map { |bucket| bucket_json(bucket) }
    }
  end

  # GET /api/v1/buckets/:id
  def show
    render json: {
      bucket: bucket_json(@bucket),
      bucket_images: @bucket.bucket_images.includes(:image).map { |bi| bucket_image_json(bi) },
      bucket_schedules: @bucket.bucket_schedules.map { |bs| bucket_schedule_json(bs) }
    }
  end

  # POST /api/v1/buckets
  def create
    @bucket = current_user.buckets.build(bucket_params)
    
    if @bucket.save
      render json: {
        bucket: bucket_json(@bucket),
        message: 'Bucket created successfully'
      }, status: :created
    else
      render json: {
        errors: @bucket.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/buckets/:id
  def update
    if @bucket.update(bucket_params)
      render json: {
        bucket: bucket_json(@bucket),
        message: 'Bucket updated successfully'
      }
    else
      render json: {
        errors: @bucket.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/buckets/:id
  def destroy
    @bucket.destroy
    render json: { message: 'Bucket deleted successfully' }
  end

  # GET /api/v1/buckets/:id/page/:page_num
  def page
    page_num = params[:page_num].to_i
    row_size = 4
    rows_to_show = 3
    skip = row_size * rows_to_show * (page_num - 1)
    take = row_size * rows_to_show

    @bucket_images = @bucket.bucket_images
                           .includes(:image)
                           .order(:friendly_name)
                           .offset(skip)
                           .limit(take)

    render json: {
      bucket_images: @bucket_images.map { |bi| bucket_image_json(bi) },
      pagination: {
        page: page_num,
        row_size: row_size,
        rows_to_show: rows_to_show,
        total: @bucket.bucket_images.count
      }
    }
  end

  # GET /api/v1/buckets/:id/images
  def images
    @bucket_images = @bucket.bucket_images.includes(:image).order(:friendly_name)
    render json: {
      bucket_images: @bucket_images.map { |bi| bucket_image_json(bi) }
    }
  end

  # GET /api/v1/buckets/:id/images/:image_id
  def single_image
    @bucket_image = @bucket.bucket_images.find(params[:image_id])
    render json: {
      bucket_image: bucket_image_json(@bucket_image)
    }
  end

  # POST /api/v1/buckets/:id/images/upload
  # Uploads an image to a bucket
  # Creates both an Image record and a BucketImage record
  def upload_image
    if params[:file].blank?
      return render json: { error: 'No file provided' }, status: :bad_request
    end

    uploaded_file = params[:file]
    
    # For now, we'll store files locally. Later we'll integrate Digital Ocean Spaces
    # Generate a unique filename to prevent collisions
    file_extension = File.extname(uploaded_file.original_filename)
    unique_filename = "#{SecureRandom.uuid}#{file_extension}"
    
    # Create directory if it doesn't exist
    upload_dir = Rails.root.join('public', 'uploads', Rails.env.to_s)
    FileUtils.mkdir_p(upload_dir) unless Dir.exist?(upload_dir)
    
    # Save the file
    file_path = upload_dir.join(unique_filename)
    File.open(file_path, 'wb') do |file|
      file.write(uploaded_file.read)
    end
    
    # Store relative path for database
    relative_path = "uploads/#{Rails.env}/#{unique_filename}"
    
    # Extract friendly name from original filename (without extension)
    friendly_name = File.basename(uploaded_file.original_filename, file_extension)
    
    # Create Image record
    image = Image.new(
      file_path: relative_path,
      friendly_name: friendly_name
    )
    
    if image.save
      # Create BucketImage record linking the image to this bucket
      bucket_image = @bucket.bucket_images.build(
        image_id: image.id,
        friendly_name: friendly_name
      )
      
      if bucket_image.save
        render json: {
          bucket_image: bucket_image_json(bucket_image),
          message: 'Image uploaded successfully'
        }, status: :created
      else
        # If bucket_image fails to save, clean up the image
        image.destroy
        File.delete(file_path) if File.exist?(file_path)
        render json: {
          errors: bucket_image.errors.full_messages
        }, status: :unprocessable_entity
      end
    else
      # If image fails to save, clean up the file
      File.delete(file_path) if File.exist?(file_path)
      render json: {
        errors: image.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/buckets/:id/images/:image_id
  def update_image
    # Check if a new file is being uploaded (for image editing)
    if params[:file].present?
      uploaded_file = params[:file]
      
      # Generate a unique filename
      file_extension = File.extname(uploaded_file.original_filename)
      unique_filename = "#{SecureRandom.uuid}#{file_extension}"
      
      # Create directory if it doesn't exist
      upload_dir = Rails.root.join('public', 'uploads', Rails.env.to_s)
      FileUtils.mkdir_p(upload_dir) unless Dir.exist?(upload_dir)
      
      # Save the new file
      file_path = upload_dir.join(unique_filename)
      File.open(file_path, 'wb') do |file|
        file.write(uploaded_file.read)
      end
      
      # Delete old file if it exists
      old_file_path = Rails.root.join('public', @bucket_image.image.file_path)
      File.delete(old_file_path) if File.exist?(old_file_path)
      
      # Update the image record with new file path
      relative_path = "uploads/#{Rails.env}/#{unique_filename}"
      @bucket_image.image.update(file_path: relative_path)
      
      render json: {
        bucket_image: bucket_image_json(@bucket_image),
        message: 'Image updated successfully'
      }
    elsif bucket_image_params.present?
      # Update metadata only
      if @bucket_image.update(bucket_image_params)
        render json: {
          bucket_image: bucket_image_json(@bucket_image),
          message: 'Image updated successfully'
        }
      else
        render json: {
          errors: @bucket_image.errors.full_messages
        }, status: :unprocessable_entity
      end
    else
      render json: { error: 'No data provided' }, status: :bad_request
    end
  end

  # DELETE /api/v1/buckets/:id/images/:image_id
  def delete_image
    # Delete associated schedules first
    @bucket_image.bucket_schedules.destroy_all
    @bucket_image.destroy
    render json: { message: 'Image deleted successfully' }
  end

  # GET /api/v1/buckets/:id/randomize
  def randomize
    @bucket_images = @bucket.bucket_images.to_a
    return render json: { error: 'No images found in the bucket' }, status: :unprocessable_entity if @bucket_images.empty?

    # Shuffle friendly names
    friendly_names = @bucket_images.map(&:friendly_name).shuffle
    
    @bucket_images.each_with_index do |bucket_image, index|
      bucket_image.update!(friendly_name: friendly_names[index])
    end

    render json: { message: 'Bucket successfully randomized' }
  end

  # GET /api/v1/buckets/for_scheduling
  def for_scheduling
    ignore_post_now = params[:ignore_post_now] == 'true'
    
    if ignore_post_now
      @buckets = current_user.buckets.where(post_once_bucket: false)
    else
      @buckets = current_user.buckets
    end

    render json: {
      buckets: @buckets.map { |bucket| bucket_json(bucket) }
    }
  end

  private

  def set_bucket
    @bucket = current_user.buckets.find(params[:id])
  end

  def set_bucket_for_image_actions
    @bucket = current_user.buckets.find(params[:id])
  end

  def set_bucket_image
    @bucket_image = @bucket.bucket_images.find(params[:image_id])
  end

  def bucket_params
    params.require(:bucket).permit(:name, :description, :use_watermark, :post_once_bucket)
  end

  def bucket_image_params
    params.require(:bucket_image).permit(:description, :twitter_description, :use_watermark, :force_send_date, :repeat, :post_to)
  end

  def bucket_json(bucket)
    {
      id: bucket.id,
      user_id: bucket.user_id,
      name: bucket.name,
      description: bucket.description,
      use_watermark: bucket.use_watermark,
      post_once_bucket: bucket.post_once_bucket,
      created_at: bucket.created_at,
      updated_at: bucket.updated_at,
      images_count: bucket.bucket_images.count,
      schedules_count: bucket.bucket_schedules.count
    }
  end

  def bucket_image_json(bucket_image)
    {
      id: bucket_image.id,
      friendly_name: bucket_image.friendly_name,
      description: bucket_image.description,
      twitter_description: bucket_image.twitter_description,
      force_send_date: bucket_image.force_send_date,
      repeat: bucket_image.repeat,
      post_to: bucket_image.post_to,
      use_watermark: bucket_image.use_watermark,
      image: {
        id: bucket_image.image.id,
        file_path: bucket_image.image.file_path,
        source_url: bucket_image.image.get_source_url
      },
      created_at: bucket_image.created_at,
      updated_at: bucket_image.updated_at
    }
  end

  def bucket_schedule_json(bucket_schedule)
    {
      id: bucket_schedule.id,
      schedule: bucket_schedule.schedule,
      schedule_type: bucket_schedule.schedule_type,
      post_to: bucket_schedule.post_to,
      description: bucket_schedule.description,
      twitter_description: bucket_schedule.twitter_description,
      times_sent: bucket_schedule.times_sent,
      skip_image: bucket_schedule.skip_image,
      bucket_image_id: bucket_schedule.bucket_image_id,
      created_at: bucket_schedule.created_at,
      updated_at: bucket_schedule.updated_at
    }
  end
end
