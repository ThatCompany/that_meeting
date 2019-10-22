require_dependency 'watcher'

module Patches
    module ThatMeetingWatcherPatch

        def self.included(base)
            base.send(:include, InstanceMethods)
            base.class_eval do
                unloadable

                after_create :send_meeting_invitation, :if => Proc.new { |watcher| # start_time is nil on meeting creation
                    watcher.watchable.is_a?(Issue) && watcher.watchable.meeting? && watcher.watchable.start_time
                }
            end
        end

        module InstanceMethods

            def send_meeting_invitation
                if !watchable.meeting.canceled? && watchable.notify? && Setting.notified_events.include?('issue_added')
                    Mailer.attendee_invited(watchable, user).deliver
                end
            end

        end

    end
end
