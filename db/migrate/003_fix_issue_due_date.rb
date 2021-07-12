class FixIssueDueDate < Rails::VERSION::MAJOR < 5 ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]

    def self.up
        Issue.meeting.where(:due_date => nil).each do |issue|
            if issue.meeting.recurrence.any?
                if issue.meeting.recurrence.count
                    issue.update_column(:due_date, issue.meeting.last_occurrence_date.try(&:to_date))
                elsif issue.meeting.recurrence.until
                    issue.update_column(:due_date, issue.meeting.recurrence.until)
                end
            else
                issue.update_column(:due_date, issue.start_date)
            end
        end
        Issue.meeting.where.not(:due_date => nil).select{ |issue| issue.meeting.recurrence.any? && !issue.meeting.recurrence.end }.each do |issue|
            issue.update_column(:due_date, nil)
        end
    end

end
