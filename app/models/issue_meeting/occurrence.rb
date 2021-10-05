class IssueMeeting::Occurrence

    attr_accessor :issue, :start_time, :end_time, :exception

    def initialize(issue, start_time, end_time, exception = nil)
        self.issue = issue
        self.start_time = start_time
        self.end_time = end_time
        self.exception = exception
    end

    def date
        start_time.to_date
    end

end
