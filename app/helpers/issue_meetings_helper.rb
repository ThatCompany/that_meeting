module IssueMeetingsHelper

    def edit_time(time, user = nil)
        return nil unless time
        time = time.to_time if time.is_a?(String)
        user ||= User.current
        zone = user.time_zone
        local = zone ? time.in_time_zone(zone) : (time.utc? ? time.localtime : time)
        I18n.l(local, :format => '%H:%M')
    end

    def recurrence_type_options_for_select(selected)
        options_for_select([ [ l(:label_none), '' ],
                             [ l(:label_daily), 'daily' ],
                             [ l(:label_weekly), 'weekly' ],
                             [ l(:label_monthly), 'monthly' ],
                             [ l(:label_yearly), 'yearly' ] ], selected)
    end

    def recurrence_position_options_for_select(selected)
         options_for_select([ [ l(:label_first), 1 ],
                              [ l(:label_second), 2 ],
                              [ l(:label_third), 3 ],
                              [ l(:label_fourth), 4 ],
                              [ l(:label_last), -1 ] ], selected)
    end

    def recurrence_wday_options_for_select(selected)
        options_for_select(week_days.collect{ |day| [ day_name(day), day ] } +
                           [ [ l(:label_workday), 0 ] ], selected)
    end

    def recurrence_end_options_for_select(selected)
        options_for_select([ [ l(:label_never), '' ],
                             [ l(:label_after), 'count' ],
                             [ l(:label_on_date), 'until' ] ], selected)
    end

    def recurrence_week_days_checkboxes(issue)
        checkboxes = hidden_field_tag('issue[recurrence][wdays][]', '')
        selected = issue.recurrence.try(:wdays) || []
        week_days.each do |day|
            checkbox = check_box_tag('issue[recurrence][wdays][]', day, selected.include?(day))
            checkboxes << content_tag('label', checkbox + day_name(day), :class => 'inline')
        end
        checkboxes.html_safe
    end

    def recurrence_interval_label
        content_tag('span', '', :id => 'recurrence_interval',
                                :data => %w(daily weekly monthly yearly).map{ |type| [ type, l("label_interval_#{type}") ] }.to_h)
    end

    def week_days
        start_of_week = Setting.start_of_week
        start_of_week = l(:general_first_day_of_week, :default => '1') if start_of_week.blank?
        (1..7).to_a.rotate(start_of_week.to_i - 1)
    end

end
