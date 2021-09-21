require 'redmine'

require_dependency 'hooks/that_meeting_hook'

Rails.logger.info 'Starting That Meeting plugin for Redmine'

IssueQuery.add_available_column(QueryColumn.new(:formatted_start_time, :caption => :field_start_time))
IssueQuery.add_available_column(QueryColumn.new(:formatted_end_time, :caption => :field_end_time))
IssueQuery.add_available_column(QueryColumn.new(:recurrence))

Rails.configuration.to_prepare do
    unless IssuesController.included_modules.include?(IssueMeetingsHelper)
        IssuesController.send(:helper, :issue_meetings)
        IssuesController.send(:include, IssueMeetingsHelper)
    end
    unless IssuesController.included_modules.include?(Patches::ThatMeetingIssuesControllerPatch)
        IssuesController.send(:include, Patches::ThatMeetingIssuesControllerPatch)
    end
    unless CalendarsController.included_modules.include?(Patches::ThatMeetingCalendarsControllerPatch)
        CalendarsController.send(:include, Patches::ThatMeetingCalendarsControllerPatch)
    end
    unless ActionView::Base.included_modules.include?(I18n::TimeFormatter)
        ActionView::Base.send(:include, I18n::TimeFormatter)
    end
    unless ApplicationHelper.included_modules.include?(Patches::ThatMeetingApplicationHelperPatch)
        ApplicationHelper.send(:include, Patches::ThatMeetingApplicationHelperPatch)
    end
    unless IssuesHelper.included_modules.include?(Patches::ThatMeetingIssuesHelperPatch)
        IssuesHelper.send(:include, Patches::ThatMeetingIssuesHelperPatch)
    end
    unless WatchersHelper.included_modules.include?(Patches::ThatMeetingWatchersHelperPatch)
        WatchersHelper.send(:include, Patches::ThatMeetingWatchersHelperPatch)
    end
    unless MyHelper.included_modules.include?(Patches::ThatMeetingMyHelperPatch)
        MyHelper.send(:include, Patches::ThatMeetingMyHelperPatch)
    end
    unless Redmine::Helpers::Calendar.included_modules.include?(Patches::ThatMeetingCalendarPatch)
        Redmine::Helpers::Calendar.send(:include, Patches::ThatMeetingCalendarPatch)
    end
    unless Issue.included_modules.include?(Patches::ThatMeetingIssuePatch)
        Issue.send(:include, Patches::ThatMeetingIssuePatch)
    end
    unless Journal.included_modules.include?(Patches::ThatMeetingJournalPatch)
        Journal.send(:include, Patches::ThatMeetingJournalPatch)
    end
    unless JournalDetail.included_modules.include?(Patches::ThatMeetingJournalDetailPatch)
        JournalDetail.send(:include, Patches::ThatMeetingJournalDetailPatch)
    end
    unless Watcher.included_modules.include?(Patches::ThatMeetingWatcherPatch)
        Watcher.send(:include, Patches::ThatMeetingWatcherPatch)
    end
    unless Mailer.included_modules.include?(Patches::ThatMeetingMailerPatch)
        Mailer.send(:include, Patches::ThatMeetingMailerPatch)
    end
    unless MailHandler.included_modules.include?(Patches::ThatMeetingMailHandlerPatch)
        MailHandler.send(:include, Patches::ThatMeetingMailHandlerPatch)
    end
end

Redmine::Plugin.register :that_meeting do
    name 'That Meeting'
    author 'Andriy Lesyuk for That Company'
    author_url 'http://www.andriylesyuk.com/'
    description 'Converts issues of the selected trackers into iCalendar events.'
    url 'https://github.com/thatcompany/that_meeting'
    version '1.0.0'

    settings :default => {
        'tracker_ids' => [],
        'hide_mails' => true,
        'cancel_status_ids' => [],
        'force_notifications' => false,
        'no_reply_notify' => false,
        'system_timezone' => (File.read('/etc/timezone').strip rescue nil),
        'timezone_format' => '%Z'
    }, :partial => 'settings/meeting'
end
