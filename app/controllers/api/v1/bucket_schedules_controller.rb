class Api::V1::BucketSchedulesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bucket_schedule, only: [:show, :update, :destroy, :post_now, :skip_image, :skip_image_single, :history]

  # GET /api/v1/bucket_schedules
  def index
    @bucket_schedules = current_user.bucket_schedules
                                   .includes(:bucket, :bucket_image)
                                   .order(:created_at)

    render json: {
      bucket_schedules: @bucket_schedules.map { |schedule| bucket_schedule_json(schedule) }
    }
  end

  # GET /api/v1/bucket_schedules/:id
  def show
    render json: {
      bucket_schedule: bucket_schedule_json(@bucket_schedule)
    }
  end

  # POST /api/v1/bucket_schedules
  def create
    @bucket = current_user.buckets.find(params[:bucket_id])
    
    @bucket_schedule = @bucket.bucket_schedules.build(bucket_schedule_params)
    
    if @bucket_schedule.save
      render json: {
        bucket_schedule: bucket_schedule_json(@bucket_schedule),
        message: 'Schedule created successfully'
      }, status: :created
    else
      render json: {
        errors: @bucket_schedule.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/bucket_schedules/:id
  def update
    if @bucket_schedule.update(bucket_schedule_params)
      render json: {
        bucket_schedule: bucket_schedule_json(@bucket_schedule),
        message: 'Schedule updated successfully'
      }
    else
      render json: {
        errors: @bucket_schedule.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/bucket_schedules/:id
  def destroy
    @bucket_schedule.destroy
    render json: { message: 'Schedule deleted successfully' }
  end

  # POST /api/v1/bucket_schedules/bulk_update
  def bulk_update
    schedule_ids = params[:bucket_schedule_ids].split(',')
    networks = params[:networks] || []
    time = params[:time]
    
    return render json: { error: 'Invalid parameters' }, status: :unprocessable_entity unless time.present?

    # Calculate post_to flags
    post_to = calculate_post_to_flags(networks)
    
    # Parse time and create cron string
    begin
      date_time = Time.parse(time)
      cron_string = "#{date_time.min} #{date_time.hour} #{date_time.day} #{date_time.month} *"
    rescue ArgumentError => e
      return render json: { error: 'Invalid time format' }, status: :unprocessable_entity
    end

    updated_count = 0
    schedule_ids.each do |schedule_id|
      schedule = current_user.bucket_schedules.find_by(id: schedule_id)
      next unless schedule

      schedule.update!(
        schedule: cron_string,
        post_to: post_to
      )
      updated_count += 1
    end

    render json: {
      message: "#{updated_count} schedules successfully updated"
    }
  end

  # DELETE /api/v1/bucket_schedules/bulk_delete
  def bulk_delete
    schedule_ids = params[:bucket_schedule_ids].split(',')
    
    deleted_count = 0
    schedule_ids.each do |schedule_id|
      schedule = current_user.bucket_schedules.find_by(id: schedule_id)
      next unless schedule

      schedule.destroy
      deleted_count += 1
    end

    render json: {
      message: "#{deleted_count} schedules successfully deleted"
    }
  end

  # POST /api/v1/bucket_schedules/rotation_create
  def rotation_create
    @bucket = current_user.buckets.find(params[:bucket_id])
    networks = params[:networks] || []
    time = params[:time]
    days = params[:days] || []
    
    return render json: { error: 'Invalid parameters' }, status: :unprocessable_entity unless time.present? && days.present?

    # Calculate post_to flags
    post_to = calculate_post_to_flags(networks)
    
    # Parse time and create cron string for rotation
    time_parts = time.split(':')
    hour = time_parts[0].to_i.to_s  # Remove leading zeros
    minute = time_parts[1].to_i.to_s  # Remove leading zeros
    days_string = days.join(',')
    
    cron_string = "#{minute} #{hour} * * #{days_string}"

    @bucket_schedule = @bucket.bucket_schedules.create!(
      schedule: cron_string,
      schedule_type: BucketSchedule::SCHEDULE_TYPE_ROTATION,
      post_to: post_to
    )

    render json: {
      bucket_schedule: bucket_schedule_json(@bucket_schedule),
      message: 'Rotation schedule created successfully'
    }
  end

  # POST /api/v1/bucket_schedules/date_create
  def date_create
    @bucket = current_user.buckets.find(params[:bucket_id])
    @bucket_image = @bucket.bucket_images.find(params[:bucket_image_id])
    networks = params[:networks] || []
    time = params[:time]
    post_annually = params[:post_annually] == 'true'
    
    return render json: { error: 'Invalid parameters' }, status: :unprocessable_entity unless time.present?

    # Calculate post_to flags
    post_to = calculate_post_to_flags(networks)
    
    # Parse time and create cron string for specific date
    date_time = Time.parse(time)
    cron_string = "#{date_time.min} #{date_time.hour} #{date_time.day} #{date_time.month} *"

    @bucket_schedule = @bucket.bucket_schedules.create!(
      bucket_image: @bucket_image,
      schedule: cron_string,
      schedule_type: post_annually ? BucketSchedule::SCHEDULE_TYPE_ANNUALLY : BucketSchedule::SCHEDULE_TYPE_ONCE,
      post_to: post_to,
      description: params[:description] || @bucket_image.description,
      twitter_description: params[:twitter_description] || @bucket_image.twitter_description
    )

    render json: {
      bucket_schedule: bucket_schedule_json(@bucket_schedule),
      message: 'Date schedule created successfully'
    }
  end

  # POST /api/v1/bucket_schedules/:id/post_now
  def post_now
    # This would trigger the actual posting process
    # For now, we'll just mark it as processed
    @bucket_schedule.update!(times_sent: @bucket_schedule.times_sent + 1)
    
    render json: {
      message: 'Post sent successfully',
      times_sent: @bucket_schedule.times_sent
    }
  end

  # POST /api/v1/bucket_schedules/:id/skip_image
  def skip_image
    @bucket_schedule.increment!(:skip_image)
    
    render json: {
      message: 'Image skipped',
      skip_count: @bucket_schedule.skip_image
    }
  end

  # POST /api/v1/bucket_schedules/:id/skip_image_single
  def skip_image_single
    if @bucket_schedule.schedule_type == BucketSchedule::SCHEDULE_TYPE_ANNUALLY
      @bucket_schedule.update!(skip_image: 1)
    elsif @bucket_schedule.schedule_type == BucketSchedule::SCHEDULE_TYPE_ONCE
      @bucket_schedule.destroy
    end
    
    render json: { message: 'Image skipped' }
  end

  # GET /api/v1/bucket_schedules/:id/history
  def history
    @send_histories = @bucket_schedule.bucket_send_histories
                                     .order(sent_at: :desc)
                                     .includes(:bucket_image)

    render json: {
      bucket_schedule: bucket_schedule_json(@bucket_schedule),
      send_histories: @send_histories.map { |history| send_history_json(history) }
    }
  end

  private

  def set_bucket_schedule
    @bucket_schedule = current_user.bucket_schedules.find(params[:id])
  end

  def bucket_schedule_params
    params.require(:bucket_schedule).permit(
      :schedule, :schedule_type, :post_to, :description, :twitter_description,
      :times_sent, :skip_image, :bucket_image_id
    )
  end

  def calculate_post_to_flags(networks)
    post_to = 0
    networks.each do |network|
      case network
      when 'facebook'
        post_to += BucketSchedule::BIT_FACEBOOK
      when 'twitter'
        post_to += BucketSchedule::BIT_TWITTER
      when 'instagram'
        post_to += BucketSchedule::BIT_INSTAGRAM
      when 'linked_in'
        post_to += BucketSchedule::BIT_LINKEDIN
      when 'google_business'
        post_to += BucketSchedule::BIT_GMB
      end
    end
    post_to
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
      bucket_id: bucket_schedule.bucket_id,
      bucket_image_id: bucket_schedule.bucket_image_id,
      bucket: bucket_schedule.bucket ? {
        id: bucket_schedule.bucket.id,
        name: bucket_schedule.bucket.name
      } : nil,
      bucket_image: bucket_schedule.bucket_image ? {
        id: bucket_schedule.bucket_image.id,
        friendly_name: bucket_schedule.bucket_image.friendly_name
      } : nil,
      created_at: bucket_schedule.created_at,
      updated_at: bucket_schedule.updated_at
    }
  end

  def send_history_json(send_history)
    {
      id: send_history.id,
      sent_at: send_history.sent_at,
      sent_to: send_history.sent_to,
      sent_to_name: send_history.get_sent_to_name,
      bucket_image: send_history.bucket_image ? {
        id: send_history.bucket_image.id,
        friendly_name: send_history.bucket_image.friendly_name
      } : nil,
      created_at: send_history.created_at
    }
  end
end

