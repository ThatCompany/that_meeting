require_dependency 'my_helper'

module Patches
    module ThatMeetingMyHelperPatch

        def self.included(base)
            base.send(:include, InstanceMethods)
            base.class_eval do
                unloadable

                alias_method :render_calendar_block, :render_calendar_block_with_meetings
            end
        end

        module InstanceMethods

            def render_calendar_block_with_meetings(block, settings)
                calendar = Redmine::Helpers::Calendar.new(User.current.today, current_language, :week)
                calendar.events = Issue.visible.includes(:project, :tracker, :priority, :assigned_to)
                                               .references(:project, :tracker, :priority, :assigned_to)
                                               .where(:project_id => User.current.projects.pluck(:id))
                                               .where("(start_date >= ? AND start_date <= ?) OR (due_date >= ? AND due_date <= ?)",
                                                      calendar.startdt, calendar.enddt, calendar.startdt, calendar.enddt).to_a

                if Setting.plugin_that_meeting['tracker_ids'].is_a?(Array) && Setting.plugin_that_meeting['tracker_ids'].any?
                    meetings = []
                    issues = Issue.visible.includes(:project, :tracker, :priority, :assigned_to)
                                          .references(:project, :tracker, :priority, :assigned_to)
                                          .where("tracker_id IN (?) AND start_date <= ? AND (due_date >= ? OR due_date IS NULL)",
                                                 Setting.plugin_that_meeting['tracker_ids'], calendar.enddt, calendar.startdt)
                    issues.each do |issue|
                        meetings += issue.meeting.occurrences_between(calendar.startdt, calendar.enddt)
                    end
                    calendar.meetings = meetings
                end

                render :partial => 'my/blocks/calendar', :locals => { :calendar => calendar, :block => block }
            end

        end

    end
end
