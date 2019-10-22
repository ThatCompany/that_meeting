require_dependency 'journal_detail'

module Patches
    module ThatMeetingJournalDetailPatch

        def self.included(base)
            base.send(:include, InstanceMethods)
            base.class_eval do
                unloadable

                alias_method_chain :normalize, :meeting
            end
        end

        module InstanceMethods

            def normalize_with_meeting(arg)
                case arg
                when Time
                    arg = self.class.default_timezone == :utc ? arg.utc : arg.localtime
                    arg.strftime('%H:%M:%S')
                when IssueMeeting::Recurrence
                    arg.any? ? arg.to_s : nil
                else
                    normalize_without_meeting(arg)
                end
            end

        end

    end
end
