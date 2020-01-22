require_dependency 'watchers_helper'

module Patches
    module ThatMeetingWatchersHelperPatch

        def self.included(base)
            base.send(:include, InstanceMethods)
            base.class_eval do
                unloadable

                alias_method :watchers_list_without_meeting, :watchers_list
                alias_method :watchers_list, :watchers_list_with_meeting
            end
        end

        module InstanceMethods

            def watchers_list_with_meeting(object)
                content = watchers_list_without_meeting(object)
                if object.is_a?(Issue) && object.meeting?
                    js = "$('#watchers h3').text('#{j l(:label_attendees)} (#{object.watcher_users.size})');"
                    js << "$('#watchers ul.watchers').addClass('attendees');"
                    object.watcher_users.collect do |user|
                        acceptance = object.meeting.responses_by_user[user.id].try(:downcase)
                        js << "$('#watchers li.user-#{user.id}').append($('<span>', { 'class': 'icon-only meeting-status icon-meeting-#{acceptance || 'needs-action'}', " +
                                                                                      "title: '#{j l("label_meeting_status_#{acceptance || 'none'}")}' }));"
                    end if content.present?
                    content << javascript_tag(js)
                end
                content
            end

        end

    end
end
