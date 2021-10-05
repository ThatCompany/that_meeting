module Hooks
    class ThatMeetingHook  < Redmine::Hook::ViewListener
        include I18n::TimeFormatter

        def view_layouts_base_html_head(context = {})
            stylesheets = stylesheet_link_tag('that_meeting', :plugin => 'that_meeting')
            if File.exists?(File.join(File.dirname(__FILE__), "../assets/stylesheets/#{Setting.ui_theme}.css"))
                stylesheets << stylesheet_link_tag(Setting.ui_theme, :plugin => 'that_meeting')
            end
            stylesheets
        end

        def helper_issues_show_detail_after_setting(context = {})
            if %w(attr occurrence).include?(context[:detail].property) && %w(start_time end_time).include?(context[:detail].prop_key)
                format_method = context[:controller].is_a?(Mailer) ? :format_time_with_timezone : :format_time
                include_date = context[:detail].property == 'occurrence'
                context[:detail].old_value = send(format_method, context[:detail].old_value, include_date) unless context[:detail].old_value.blank?
                context[:detail].value = send(format_method, context[:detail].value, include_date) unless context[:detail].value.blank?
            end
            if context[:detail].property == 'occurrence'
                context[:detail].prop_key = l(context[:detail].value.blank? ? :label_occurrence : "field_occurrence_#{context[:detail].prop_key}".to_sym)
                context[:detail].property = 'attr' # HACK: Otherwise it wll be ignored
            end
        end

        def view_issues_context_menu_start(context = {})
            issue = context[:issues].first if context[:issues].size == 1
            if issue && issue.meeting? && issue.meeting.recurrence.any? && context[:request].params[:date]
                context[:hook_caller].content_tag(:li, context[:hook_caller].context_menu_link(l(:label_edit_occurrence),
                                                                                               context[:hook_caller].edit_issue_occurrence_path(issue, :date => context[:request].params[:date]),
                                                                                               :class => 'icon icon-edit-occurrence', :disabled => !context[:can][:edit]))
            end
        end

        def view_issues_context_menu_end(context = {})
            issue = context[:issues].first if context[:issues].size == 1
            if issue && issue.meeting? && issue.meeting.recurrence.any? && context[:request].params[:date]
                context[:hook_caller].content_tag(:li, context[:hook_caller].context_menu_link(l(:label_delete_occurrence),
                                                                                               context[:hook_caller].issue_occurrence_path(issue, :date => context[:request].params[:date], :back_url => context[:back]),
                                                                                               :method => :delete, :data => { :confirm => l(:text_issue_occurrences_destroy_confirmation) },
                                                                                               :class => 'icon icon-del-occurrence', :disabled => !context[:can][:edit]))
            end
        end

        render_on :view_issues_form_details_bottom, :partial => 'meetings/form'
        render_on :view_issues_show_details_bottom, :partial => 'meetings/show'
        render_on :view_issues_show_description_bottom, :partial => 'meetings/exceptions'
        render_on :view_issues_sidebar_queries_bottom, :partial => 'meetings/sidebar'

        render_on :view_calendars_show_bottom, :partial => 'meetings/calendar'

    end
end
