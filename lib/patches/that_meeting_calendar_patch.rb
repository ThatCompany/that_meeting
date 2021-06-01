require_dependency 'redmine/helpers/calendar'

module Patches
    module ThatMeetingCalendarPatch

        def self.included(base)
            base.send(:include, InstanceMethods)
            base.class_eval do
                unloadable

                alias_method :initialize_without_meetings, :initialize
                alias_method :initialize, :initialize_with_meetings

                alias_method :events_on_without_meetings, :events_on
                alias_method :events_on, :events_on_with_meetings
            end
        end

        module InstanceMethods

            def initialize_with_meetings(date, lang = current_language, period = :month)
                initialize_without_meetings(date, lang, period)
                @meetings_by_days = {}
            end

            def meetings=(meetings)
                @meetings_by_days = meetings.group_by{ |meeting| meeting.start_time.to_date }
                                            .transform_values{ |meetings| meetings.map(&:issue) }
            end

            def events_on_with_meetings(day)
                (events_on_without_meetings(day) + (@meetings_by_days[day] || [])).uniq
            end

        end

    end
end
