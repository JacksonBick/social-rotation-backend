class RenameTypeToScheduleTypeInBucketSchedules < ActiveRecord::Migration[7.1]
  def change
    rename_column :bucket_schedules, :type, :schedule_type
  end
end
