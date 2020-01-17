class FixIssueMeetingsRecurrenceValues < ActiveRecord::Migration

    def self.up
        if Setting.plugin_that_meeting['tracker_ids'].is_a?(Array) && Setting.plugin_that_meeting['tracker_ids'].any?
            IssueMeeting.where.not("#{IssueMeeting.table_name}.recurrence LIKE '%:type: :%'").update_all(:recurrence => nil)
        end
    end

end
