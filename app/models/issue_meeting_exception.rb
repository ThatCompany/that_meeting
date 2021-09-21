class IssueMeetingException < ActiveRecord::Base
    include Redmine::SafeAttributes

    belongs_to :meeting, :class_name => 'IssueMeeting'

    attr_reader :current_journal
    delegate :notes, :notes=, :private_notes, :private_notes=, :to => :current_journal, :allow_nil => true

    validates_presence_of :date
    validates :date, :start_date, :date => true
    validates :start_time, :end_time, :time => true
    validates_uniqueness_of :date, :scope => :meeting_id
    validate :validate_time

    after_save :create_save_journal
    after_destroy :create_reset_journal

    safe_attributes :start_date, :start_time, :end_time, :if => lambda { |exception, user|
        exception.meeting.issue.attributes_editable?(user)
    }
    safe_attributes :notes, :if => lambda { |exception, user| exception.meeting.issue.notes_addable?(user) }
    safe_attributes :private_notes, :if => lambda { |exception, user| user.allowed_to?(:set_notes_private, exception.meeting.issue.project) }

    scope :sorted, lambda { order(:date) }

    def self.find_by_date_param(date)
        find_by_start_date(date) || find_by_date(date)
    end

    def date_param
        start_date_was || date
    end

    def datetime
        if meeting.time_zone
            meeting.time_zone.parse("#{date.strftime('%Y-%m-%d')} #{meeting.start_time.strftime('%H:%M:%S')}")
        else
            DateTime.new(date.year, date.month, date.day, meeting.start_time.hour, meeting.start_time.min, meeting.start_time.sec, meeting.start_time.zone)
        end
    end

    def start_time=(arg)
        super(parse_time(arg))
    end

    def end_time=(arg)
        super(parse_time(arg))
    end

    def start_time
        time = read_attribute(:start_time)
        time.is_a?(Time) ? full_date(start_date || Date.today, time) : time
    end

    def end_time
        time = read_attribute(:end_time)
        time.is_a?(Time) ? full_date(start_date || Date.today, time) : time
    end

    def nullify
        self.start_date = nil
        self.start_time = nil
        self.end_time   = nil
    end

    def init_journal(user, notes = '')
        @current_journal ||= Journal.new(:journalized => meeting.issue, :user => user, :notes => notes)
    end

    def full_date(date, time)
        if meeting.time_zone
            time = time.in_time_zone(meeting.time_zone) if Redmine::VERSION::MAJOR > 3
            meeting.time_zone.parse("#{date.strftime('%Y-%m-%d')} #{time.strftime('%H:%M:%S')}")
        else
            DateTime.new(date.year, date.month, date.day, time.hour, time.min, time.sec, time.zone).utc # Can be inaccurate when DST changes
        end
    end

private

    def validate_time
        if start_date
            errors.add(:base, l(:error_date_cannot_be_less_than_meeting_start_date)) if start_date < meeting.issue.start_date
            errors.add(:base, l(:error_date_cannot_be_greater_than_meeting_due_date)) if meeting.issue.due_date && start_date > meeting.issue.due_date
            unless new_record? && start_date == date
                occurrences = meeting.occurrences_between(start_date, start_date).reject{ |occurrence| occurrence.exception && occurrence.exception.id == id }
                errors.add(:base, l(:label_date) + ' ' + l('activerecord.errors.messages.taken')) if occurrences.detect{ |occurrence| occurrence.start_time.to_date == start_date }
            end
        end
        if start_time
            occurrences = meeting.occurrences_between(start_date, start_date, :exdates => false).reject{ |occurrence| occurrence.exception && occurrence.exception.id == id }
            errors.add(:start_time, :taken) if occurrences.detect{ |occurrence| occurrence.start_time == start_time }
        end
        if start_time && end_time && end_time <= start_time
            errors.add(:end_time, :greater_than_start_time)
        end
    end

    def create_save_journal
        init_journal(User.current) unless current_journal
        old_start_date = (Rails::VERSION::MAJOR < 5 || (Rails::VERSION::MAJOR == 5 && Rails::VERSION::MINOR < 1) ? start_date_was : start_date_before_last_save) || date
        old_start_time = (Rails::VERSION::MAJOR < 5 || (Rails::VERSION::MAJOR == 5 && Rails::VERSION::MINOR < 1) ? start_time_was : start_time_before_last_save) || meeting.start_time
        old_start_time = full_date(old_start_date, old_start_time)
        current_journal.details << JournalDetail.new(:property => 'occurrence', :prop_key => 'start_time',
                                                     :old_value => old_start_time.try(&:to_datetime), :value => start_time.try(&:to_datetime)) if old_start_time != start_time
        if start_time # Otherwise occurrence was deleted
            old_end_time = (Rails::VERSION::MAJOR < 5 || (Rails::VERSION::MAJOR == 5 && Rails::VERSION::MINOR < 1) ? end_time_was : end_time_before_last_save) || meeting.end_time
            old_end_time = full_date(old_start_date, old_end_time) if old_end_time
            current_journal.details << JournalDetail.new(:property => 'occurrence', :prop_key => 'end_time',
                                                         :old_value => old_end_time.try(&:to_datetime), :value => end_time.try(&:to_datetime)) if old_end_time != end_time
        end
        current_journal.save
    end

    def create_reset_journal
        init_journal(User.current) unless current_journal
        old_start_time = start_time ? full_date(start_date, start_time) : nil
        old_end_time   = end_time ? full_date(start_date, end_time) : nil
        new_start_time = full_date(date, meeting.start_time)
        new_end_time   = full_date(date, meeting.end_time) if meeting.end_time
        current_journal.details << JournalDetail.new(:property => 'occurrence', :prop_key => 'start_time',
                                                     :old_value => old_start_time.try(&:to_datetime), :value => new_start_time.try(&:to_datetime))
        current_journal.details << JournalDetail.new(:property => 'occurrence', :prop_key => 'end_time',
                                                     :old_value => old_end_time.try(&:to_datetime), :value => new_end_time.try(&:to_datetime)) if old_end_time != new_end_time
        current_journal.save
    end

    def parse_time(arg, user = User.current)
        if arg.is_a?(String) && !arg.empty?
            arg = (user.time_zone || meeting.time_zone).parse("#{(start_date || Date.today).strftime('%Y-%m-%d')} #{arg}").try(&:localtime)
        else
            arg
        end
    end

end
