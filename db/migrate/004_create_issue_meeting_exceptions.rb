class CreateIssueMeetingExceptions < Rails::VERSION::MAJOR < 5 ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]

    def self.up
        create_table :issue_meeting_exceptions do |t|
            t.column :meeting_id, :integer,  :null => false
            t.column :date,       :date,     :null => false
            t.column :start_date, :date
            t.column :start_time, :time
            t.column :end_time,   :time
            t.column :created_on, :datetime, :null => false
            t.column :updated_on, :datetime
        end
        add_index :issue_meeting_exceptions, :meeting_id, :name => :issue_meeting_exceptions_meeting_ids
        add_index :issue_meeting_exceptions, :date, :name => :issue_meeting_exceptions_dates
        add_index :issue_meeting_exceptions, :start_date, :name => :issue_meeting_exceptions_start_dates
    end

    def self.down
        drop_table :issue_meeting_exceptions
    end

end
