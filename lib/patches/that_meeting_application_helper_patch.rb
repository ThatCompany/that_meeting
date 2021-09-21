require_dependency 'application_helper'

module Patches
    module ThatMeetingApplicationHelperPatch

        def self.included(base)
            base.send(:include, InstanceMethods)
            base.class_eval do
                unloadable

                alias_method :context_menu_without_meetings, :context_menu
                alias_method :context_menu, :context_menu_with_meetings
            end
        end

        module InstanceMethods

            def context_menu_with_meetings
                context_menu_without_meetings

                unless @meeting_context_menu_included
                    content_for :header_tags do
                        javascript_include_tag('context_menu', :plugin => 'that_meeting')
                    end
                    @meeting_context_menu_included = true
                end
                nil
            end

        end

    end
end
