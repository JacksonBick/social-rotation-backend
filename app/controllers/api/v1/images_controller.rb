# Images Controller
# Handles image management for RSS feeds and buckets
class Api::V1::ImagesController < ApplicationController
  before_action :authenticate_user!

  # POST /api/v1/images
  def create
    @image = Image.new(image_params)

    if @image.save
      render json: {
        id: @image.id,
        file_path: @image.file_path,
        friendly_name: @image.friendly_name,
        created_at: @image.created_at
      }, status: :created
    else
      render json: {
        errors: @image.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def image_params
    params.permit(:file_path, :friendly_name)
  end
end
