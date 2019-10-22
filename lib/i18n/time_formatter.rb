module I18n
    module TimeFormatter

        # Rework of I18n#format_time
        def format_time_with_timezone(time, include_date = true, user = User.current)
            return nil unless time
            options = { }
            options[:format] = Setting.time_format.blank? ? :time : Setting.time_format
            timezone_format = Setting.plugin_that_meeting['timezone_format'] || '%Z'
            time = time.to_time if time.is_a?(String)
            local = user && user.time_zone ? time.in_time_zone(user.time_zone) : (time.utc? ? time.localtime : time)
            (include_date ? "#{format_date(local)} " : '') + I18n.l(local, options) + I18n.l(local, :format => " #{timezone_format}")
        end

    end
end
