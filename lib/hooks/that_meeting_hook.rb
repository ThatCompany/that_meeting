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
            if context[:detail].property == 'attr' && %w(start_time end_time).include?(context[:detail].prop_key)
                format_method = context[:controller].is_a?(Mailer) ? :format_time_with_timezone : :format_time
                context[:detail].old_value = send(format_method, context[:detail].old_value, false) unless context[:detail].old_value.blank?
                context[:detail].value = send(format_method, context[:detail].value, false) unless context[:detail].value.blank?
            end
        end

        render_on :view_issues_form_details_bottom, :partial => 'meetings/form'
        render_on :view_issues_show_details_bottom, :partial => 'meetings/show'

    end
end
