class IssueMeeting::Recurrence
    include Redmine::I18n
    extend ActiveModel::Naming

    attr_accessor :type, :wdays, :wday, :day, :month, :position, :count, :until

    TYPE_DAILY   = :daily
    TYPE_WEEKLEY = :weekly
    TYPE_MONTHLY = :monthly
    TYPE_YEARLY  = :yearly

    WEEKDAYS = %w(MO TU WE TH FR SA SU)

    BY_DAY      = :day
    BY_POSITION = :position

    def self.load(str)
        new(YAML.load(str.to_s)) unless str.nil?
    end

    def self.dump(value)
        return nil unless value.respond_to?(:to_hash)
        YAML.dump(value.to_hash.symbolize_keys)
    end

    def self.human_attribute_name(name, options = {})
        l("recurrence_#{name}")
    end

    def self.lookup_ancestors
        [ self ]
    end

    def initialize(attributes = {})
        attributes.symbolize_keys.except(:monthly_by, :yearly_by).each do |name, value|
            send("#{name}=", value)
        end
    end

    def for(issue)
        @issue = issue
        self
    end

    def type=(arg)
        if arg.blank?
            @type = nil
        elsif [ TYPE_DAILY, TYPE_WEEKLEY, TYPE_MONTHLY, TYPE_YEARLY ].include?(arg.to_sym)
            @type = arg.to_sym
        else
            @type = arg
            add_error(:type, :invalid)
        end
    end

    def daily?
        type == TYPE_DAILY
    end

    def weekly?
        type == TYPE_WEEKLEY
    end

    def monthly?
        type == TYPE_MONTHLY
    end

    def yearly?
        type == TYPE_YEARLY
    end

    def any?
        !!type
    end

    def by
        if @day
            BY_DAY
        elsif @position
            BY_POSITION
        else
            BY_DAY
        end
    end

    def by_day?
        by == BY_DAY
    end

    def by_position?
        by == BY_POSITION
    end

    def wdays=(arg)
        args = Array.wrap(arg).reject{ |value| value.to_s == '' }
        if args.all?{ |value| value.to_s =~ %r{\A\d+\z} }
            @wdays = args.map(&:to_i).sort
            add_error(:wday, :invalid) unless @wdays.all?{ |day| (1..7).include?(day) }
        else
            @wdays = args
            add_error(:wday, :invalid)
        end
    end

    def wdays
        @wdays || (@issue && @issue.start_date ? [ @issue.start_date.cwday ] : [])
    end

    def wday=(arg)
        if arg.to_s =~ %r{\A\d+\z}
            @wday = arg.to_i
            add_error(:wday, :invalid) unless (0..7).include?(@wday)
        else
            @wday = arg
            add_error(:wday, :invalid)
        end
    end

    def wday
        @wday || if @issue && @issue.start_date
            @issue.start_date.cwday
        else
            start_of_week = Setting.start_of_week
            start_of_week = l(:general_first_day_of_week, :default => '1') if start_of_week.blank?
            start_of_week.to_i
        end
    end

    def day=(arg)
        if arg.to_s =~ %r{\A\d+\z}
            @day = arg.to_i
            add_error(:day, :invalid) unless (1..31).include?(@day)
        else
            @day = arg
            add_error(:day, :invalid)
        end
    end

    def day
        @day || (@issue && @issue.start_date ? @issue.start_date.mday : 1)
    end

    def month=(arg)
        if arg.to_s =~ %r{\A\d+\z}
            @month = arg.to_i
            add_error(:month, :invalid) unless (1..12).include?(@month)
        else
            @month = arg
            add_error(:month, :invalid)
        end
    end

    def month
        @month || (@issue && @issue.start_date ? @issue.start_date.month : 1)
    end

    def dmonth
        by_day? ? month : (@issue && @issue.start_date ? @issue.start_date.month : 1)
    end

    def position=(arg)
        if arg.to_s =~ %r{\A-?\d+\z}
            @position = arg.to_i
        else
            @position = arg
            add_error(:position, :invalid)
        end
    end

    def position
        @position || if @issue && @issue.start_date
            nwday = (@issue.start_date.mday - 1) / 7
            nwday > 3 ? -1 : nwday + 1
        else
            1
        end
    end

    def every=(arg)
        if arg.to_s =~ %r{\A\d+\z}
            @every = arg.to_i
            add_error(:every, :greater_than, :count => 0) if @every < 1
        else
            @every = arg
            add_error(:every, :not_a_number)
        end
    end

    def every
        @every || 1
    end

    def end
        if defined?(@count)
            :count
        elsif defined?(@until)
            :until
        end
    end

    def count=(arg)
        if arg.to_s =~ %r{\A\d+\z}
            @count = arg.to_i
            add_error(:count, :greater_than, :count => 0) if @count < 1
        else
            @count = arg
            add_error(:count, :not_a_number)
        end
    end

    def count
        @count || 1
    end

    def until=(arg)
        @until = arg.to_date
        add_error(:until, :blank) unless @until
    rescue ArgumentError
        @until = arg
        add_error(:until, :not_a_date)
    end

    def errors
        @errors || ActiveModel::Errors.new(self)
    end

    def read_attribute_for_validation(name)
        send(name)
    end

    def valid?
        add_error(:wday, :blank) if weekly? && @wdays.blank?
        errors.empty?
    end
    alias :validate :valid?

    def ==(other)
        if other.is_a?(IssueMeeting::Recurrence)
            to_recur == other.to_recur
        else
            false
        end
    end

    def to_s
        if errors.empty? && type
            s = l("label_repeat_#{type}", :count => every)
            if weekly?
                s << ' ' + l(:label_repeat_on_week_day, wdays.collect{ |day| day_name(day) }.join(', '))
            elsif monthly?
                if by_day?
                    s << ' ' + l(:label_repeat_on_day, day.to_s)
                elsif by_position?
                    dname = (wday == 0) ? l(:label_workday).downcase : day_name(wday)
                    s << ' ' + l(:label_repeat_on_nth_day, :nth => position_label(position), :day => dname)
                end
            elsif yearly?
                if by_day?
                    s << ' ' + l(:label_repeat_on_day, I18n.l(Date.civil(Date.today.year, month, day), :format => l('date.formats.short')))
                elsif by_position?
                    dname = (wday == 0) ? l(:label_workday).downcase : day_name(wday)
                    s << ' ' + l(:label_repeat_on_nth_day_of_month, :nth => position_label(position), :day => dname, :month => month_name(month))
                end
            end
            if self.end == :count
                s << ' ' + l(:label_repeat_count, self.count)
            elsif self.end == :until
                s << ' ' + l(:label_repeat_until, format_date(self.until))
            end
            s
        else
            ''
        end
    end

    def to_hash
        attributes = {}
        instance_variables.each do |variable|
            name = variable.to_s[1..-1].to_sym
            if [ :type, :wdays, :wday, :day, :month, :position, :every, :count, :until ].include?(name)
                attributes[name] = instance_variable_get(variable)
            end
        end
        attributes.delete(:every) if attributes[:every] == 1
        attributes
    end

    # https://www.kanzaki.com/docs/ical/recur.html
    def to_recur
        if @errors.blank? && @type
            recur = "FREQ=#{@type.upcase}"
            if @wdays
                recur << ";BYDAY=#{@wdays.collect{ |day| WEEKDAYS[day-1] }.join(',')}"
            end
            if by_day?
                recur << ";BYMONTHDAY=#{@day}" if @day
            elsif by_position?
                recur << ";BYSETPOS=#{@position}" if @position
                if @wday == 0
                    workdays = (1..7).to_a - Setting.non_working_week_days.map(&:to_i)
                    recur << ";BYDAY=#{workdays.collect{ |day| WEEKDAYS[day-1] }.join(',')}"
                elsif @wday
                    recur << ";BYDAY=#{WEEKDAYS[@wday-1]}"
                end
            end
            recur << ";BYMONTH=#{@month}" if @month
            recur << ";INTERVAL=#{@every}" if @every && @every > 1
            if @count
                recur << ";COUNT=#{@count}"
            elsif @until
                recur << ";UNTIL=#{full_date(@until)}"
            end
            recur
        end
    end

    def self.from_recur(str)
        attributes = { }
        str.split(';').map{ |rule| rule.split('=') }.each do |name, value|
            case name
            when 'FREQ'
                attributes[:type] = value.downcase
            when 'BYDAY'
                attributes[:wdays] = value.split(',').collect{ |day| WEEKDAYS.index(day) }.compact.map{ |day| day + 1 }
            when 'BYMONTHDAY'
                attributes[:day] = value.to_i
            when 'BYSETPOS'
                attributes[:position] = value.to_i
            when 'BYMONTH'
                attributes[:month] = value.to_i
            when 'INTERVAL'
                attributes[:every] = value.to_i
            when 'COUNT'
                attributes[:count] = value.to_i
            when 'UNTIL'
                attributes[:until] = value
            end
        end
        if attributes[:position] && attributes[:wdays]
            if attributes[:wdays].size > 1
                workdays = (1..7).to_a - Setting.non_working_week_days.map(&:to_i)
                if workdays.sort == attributes[:wdays].sort
                    attributes.delete(:wdays)
                    attributes[:wday] = 0
                end
            else
                attributes[:wday] = attributes.delete(:wdays).first
            end
        end
        new(attributes)
    end

private

    def add_error(attribute, error, options = {})
        @errors ||= ActiveModel::Errors.new(self)
        @errors.add(attribute, l("activerecord.errors.messages.#{error}", options)) unless @errors.include?(attribute)
    end

    def position_label(position)
        if position == -1
            l(:label_last)
        elsif (1..4).include?(position)
            [ l(:label_first), l(:label_second), l(:label_third), l(:label_fourth) ][position-1]
        end
    end

    def full_date(date)
        if @issue
            if @issue.meeting && @issue.meeting.time_zone
                date = @issue.meeting.time_zone.parse("#{date.strftime('%Y-%m-%d')} #{@issue.start_time.strftime('%H:%M:%S')}")
            else
                date = DateTime.new(date.year, date.month, date.day, @issue.start_time.hour, @issue.start_time.min, @issue.start_time.sec, @issue.start_time.zone)
            end
            date.utc.strftime('%Y%m%dT%H%M%SZ')
        else
            date.strftime('%Y%m%d')
        end
    end

end
