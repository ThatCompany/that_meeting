require_dependency 'journal'

module Patches
    module ThatMeetingJournalPatch

        def self.included(base)
            base.send(:include, InstanceMethods)
            base.class_eval do
                unloadable

                before_create :reset_acceptance

                alias_method :add_attribute_detail_without_time, :add_attribute_detail
                alias_method :add_attribute_detail, :add_attribute_detail_with_time

                alias_method :send_notification_without_reply, :send_notification
                alias_method :send_notification, :send_notification_with_reply
            end
        end

        module InstanceMethods

            def add_attribute_detail_with_time(attribute, old_value, value)
                return if old_value.is_a?(Time) && value.is_a?(Time) && old_value.strftime('%H:%M') == value.strftime('%H:%M')
                add_attribute_detail_without_time(attribute, old_value, value)
            end

        private

            def reset_acceptance
                if journalized.is_a?(Issue) && journalized.meeting? && !journalized.meeting.no_responses? &&
                   details.any?{ |detail| detail.property == 'attr' && %w(start_date start_time end_time recurrence).include?(detail.prop_key) }
                    details << JournalDetail.new(:property => 'attendee', :prop_key => '')
                end
                true
            end

            def send_notification_with_reply
                if journalized.is_a?(Issue) && journalized.meeting? && Setting.plugin_that_meeting['no_reply_notify'] &&
                   details.all?{ |detail| detail.property == 'attendee' && detail.prop_key.present? }
                    self.notify = false
                end
                send_notification_without_reply
            end

        end

    end
end
