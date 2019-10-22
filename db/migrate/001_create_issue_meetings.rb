class CreateIssueMeetings < ActiveRecord::Migration

    def self.up
        create_table :issue_meetings do |t|
            t.column :issue_id,   :integer,  :null => false
            t.column :start_time, :time,     :null => false
            t.column :end_time,   :time
            t.column :recurrence, :text
            t.column :created_on, :datetime, :null => false
            t.column :updated_on, :datetime
        end
        add_index :issue_meetings, :issue_id, :unique => true, :name => :issue_meetings_issue_ids
    end

    def self.down
        drop_table :issue_meetings
    end

end
