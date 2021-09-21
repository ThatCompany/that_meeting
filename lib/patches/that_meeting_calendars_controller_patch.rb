require_dependency 'calendars_controller'

module Patches
    module ThatMeetingCalendarsControllerPatch

        def self.included(base)
            base.send(:include, InstanceMethods)
            base.class_eval do
                unloadable

                alias_method :show_without_meetings, :show
                alias_method :show, :show_with_meetings
            end
        end

        module InstanceMethods

            def show_with_meetings
                meetings_configured = Setting.plugin_that_meeting['tracker_ids'].is_a?(Array) && Setting.plugin_that_meeting['tracker_ids'].any?
                orig_request_with = request.instance_variable_get(:@env).delete('HTTP_X_REQUESTED_WITH') if meetings_configured && request.xhr?

                show_without_meetings

                if meetings_configured
                    meetings = []
                    issues = @query.base_scope.preload(:meeting => :exceptions)
                                              .where([ "(tracker_id IN (?) AND start_date <= ? AND (due_date >= ? OR due_date IS NULL))",
                                                       Setting.plugin_that_meeting['tracker_ids'], @calendar.enddt, @calendar.startdt ])
                    issues.each do |issue|
                        meetings += issue.meeting.occurrences_between(@calendar.startdt, @calendar.enddt)
                    end
                    @calendar.meetings = meetings

                    if orig_request_with
                        request.instance_variable_get(:@env)['HTTP_X_REQUESTED_WITH'] = orig_request_with
                        render :action => 'show', :layout => false
                    end
                end
            end

        end

    end
end
