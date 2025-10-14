class ChangeBucketImageIdToNullableInBucketSchedules < ActiveRecord::Migration[7.1]
  def change
    change_column_null :bucket_schedules, :bucket_image_id, true
  end
end
