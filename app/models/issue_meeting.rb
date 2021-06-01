require 'icalendar'
require 'icalendar/tzinfo'

class IssueMeeting < ActiveRecord::Base

    belongs_to :issue

    serialize :recurrence, IssueMeeting::Recurrence

    validates_presence_of :start_time
    validates :start_time, :end_time, :time => true
    validate :validate_time

    def start_time=(arg)
        super(parse_time(arg))
    end

    def end_time=(arg)
        super(parse_time(arg))
    end

    def start_time
        time = read_attribute(:start_time)
        time.is_a?(Time) ? full_date(time) : time
    end

    def end_time
        time = read_attribute(:end_time)
        time.is_a?(Time) ? full_date(time) : time
    end

    def canceled?
        Setting.plugin_that_meeting['cancel_status_ids'].is_a?(Array) && Setting.plugin_that_meeting['cancel_status_ids'].include?(issue.status_id.to_s)
    end

    def duration
        issue.estimated_hours
    end

    def recurrence
        (super || IssueMeeting::Recurrence.new).for(self.issue)
    end

    def uid
        issue.created_on.utc.strftime('%Y%m%dT%H%M%S') + '-issue-' + issue.id.to_s + '@' +
        (Setting.host_name =~ /\A(https?\:\/\/)?(.+?)(\:(\d+))?(\/.+)?\z/i ? $2 : Setting.host_name).sub(%r{\Awww\.}, '')
    end

    # https://www.kanzaki.com/docs/ical/
    def to_ical(view = nil, user = User.current, options = {})
        return nil unless start_time
        ical = Icalendar::Calendar.new
        ical.prodid = "-//Redmine//That Meeting v#{Redmine::Plugin.find(:that_meeting).version}//EN"
        ical.x_redmine_issue = issue.id.to_s
        ical.x_redmine_project = issue.project.identifier
        ical.add_timezone(time_zone.tzinfo.ical_timezone(start_time)) if time_zone
        # https://www.kanzaki.com/docs/ical/vevent.html
        ical.event do |event|
            event.uid         = uid
            event.dtstart     = Icalendar::Values::DateTime.new(start_time, :tzid => time_zone ? time_zone.tzinfo.identifier : 'UTC')
            event.dtend       = Icalendar::Values::DateTime.new(end_time, :tzid => time_zone ? time_zone.tzinfo.identifier : 'UTC') if end_time
            event.duration    = ical_duration if duration && !end_time
            event.rrule       = recurrence.to_recur if recurrence.any?
            event.summary     = issue.subject
            event.description = issue.description unless issue.description.blank?
            event.status      = canceled? ? 'CANCELLED' : 'CONFIRMED'
            event.priority    = 9 - (issue.priority.position - 1) * 8 / (IssuePriority.maximum(:position).to_i - 1)
            event.organizer   = ical_organizer(user)
            visible_attendee_users(user).each do |attendee|
                ical_params = { :cn => attendee.name }
                ical_params[:partstat] = responses_by_user[attendee.id] || 'NEEDS-ACTION'
                ical_params[:rsvp] = 'TRUE' if user && responses_by_user[attendee.id].nil? && user == attendee
                event.append_attendee Icalendar::Values::CalAddress.new("MAILTO:#{attendee.mail}", ical_params)
            end
            event.ip_class    = 'PRIVATE' if issue.is_private?
            event.categories  = issue.category.name.upcase if issue.category
            event.url         = view.issue_url(issue) if view
            issue.attachments.each do |attachment|
                event.append_attach view.download_named_attachment_url(attachment, attachment.filename)
            end if view
            if issue.parent && issue.parent.meeting
                event.related_to << Icalendar::Values::Text.new("<#{issue.parent.meeting.uid}>", :reltype => 'PARENT')
            end
            issue.children.select{ |child| child.meeting }.each do |child|
                event.related_to << Icalendar::Values::Text.new("<#{child.meeting.uid}>", :reltype => 'CHILD')
            end unless issue.leaf?
            issue.visible_journals_with_index(user).select{ |journal| journal.notes? }.each do |journal|
                event.comment << Icalendar::Values::Text.new(journal.notes)
            end if options[:comments]
            event.created       = Icalendar::Values::DateTime.new(issue.created_on.utc, :tzid => 'UTC')
            event.last_modified = Icalendar::Values::DateTime.new(issue.updated_on.utc, :tzid => 'UTC')
        end
        ical.ip_method = ical_method(user)
        ical
    end

    def visible_attendee_users(user = nil)
        attendees = issue.watcher_users.preload(:email_address)
        if Setting.plugin_that_meeting['hide_mails']
            attendees.select{ |watcher| (user && watcher == user) || !watcher.pref.hide_mail }
        else
            attendees
        end
    end

    def no_responses?
        last_acceptance = issue.acceptances.first
        !last_acceptance || last_acceptance.prop_key == ''
    end

    def responses_by_user
        @responses_by_user ||= issue.acceptances.each_with_object({}) do |detail, hash|
            break hash if detail.prop_key == ''
            hash[detail.prop_key.to_i] = detail.value unless hash.has_key?(detail.prop_key.to_i)
        end
    end

    def time_zone
        @time_zone ||= ActiveSupport::TimeZone[Setting.plugin_that_meeting['system_timezone']]
    end

    def occurrences_between(start_date, end_date, time_zone = User.current.time_zone)
        time_zone ||= self.time_zone
        start_time = time_zone.parse("#{start_date.strftime('%Y-%m-%d')} 00:00:00")
        end_time = time_zone.parse("#{end_date.strftime('%Y-%m-%d')} 23:59:59")
        map_rrule(time_zone) do |rrule|
            rrule.between(start_time, end_time)
        end.reject do |start_time|
            start_time.to_date == issue.start_date || start_time.to_date == issue.due_date
        end.collect do |start_time|
            end_time = start_time + (self.end_time - self.start_time).seconds if self.end_time
            IssueMeeting::Occurrence.new(issue, start_time, end_time)
        end
    end

    def last_occurrence_date(time_zone = User.current.time_zone)
        map_rrule(time_zone){ |rrule| rrule.all.last }.sort.last if recurrence.end
    end

private

    # https://github.com/square/ruby-rrule
    def map_rrule(time_zone = User.current.time_zone, &block)
        time_zone ||= self.time_zone
        to_ical.events.map do |event|
            event.rrule.map do |rule|
                yield RRule::Rule.new(rule.value_ical, :dtstart => event.dtstart, :tzid => event.dtstart.ical_params['tzid'])
            end
        end.flatten
    end

    def parse_time(arg, user = User.current)
        if arg.is_a?(String) && !arg.empty?
            arg = (user.time_zone || time_zone).parse("#{(issue.start_date || Date.today).strftime('%Y-%m-%d')} #{arg}").try(&:localtime)
        else
            arg
        end
    end

    def full_date(time)
        date = issue.start_date || Date.today
        if time_zone
            time = time.in_time_zone(time_zone) if Redmine::VERSION::MAJOR > 3
            time_zone.parse("#{date.strftime('%Y-%m-%d')} #{time.strftime('%H:%M:%S')}")
        else
            DateTime.new(date.year, date.month, date.day, time.hour, time.min, time.sec, time.zone).utc # Can be inaccurate when DST changes
        end
    end

    def calendar_email
        Setting.mail_from.to_s.strip if ActionMailer::Base.perform_deliveries
    end

    def ical_organizer(user = User.current)
        email = calendar_email
        email = issue.assigned_to.mail if email.blank? # In this case email visibility settings will be ignored
        options = { :cn => issue.assigned_to.name }
        if !Setting.plugin_that_meeting['hide_mails'] || (user && issue.assigned_to == user) || !!issue.assigned_to.pref.hide_mail
            options[:sent_by] = "MAILTO:#{issue.assigned_to.mail}" unless email.casecmp(issue.assigned_to.mail) == 0
        end
        Icalendar::Values::CalAddress.new("MAILTO:#{email}", options)
    end

    def ical_duration
        if duration
            string = 'PT'
            hours = duration.floor
            string << hours.to_s + 'H' if hours > 0
            minutes = ((duration - hours) * 60).round
            string << minutes.to_s + 'M' if minutes > 0
            string
        end
    end

    def ical_method(user = User.current)
        if canceled?
            'CANCEL'
        elsif user && issue.watched_by?(user) && responses_by_user[user.id].nil?
            'REQUEST'
        else
            'PUBLISH'
        end
    end

    def validate_time
        if start_time && end_time && end_time <= start_time
            errors.add(:end_time, :greater_than_start_time)
        end
    end

end
