class IssueMeeting::Occurrence

    attr_accessor :issue, :start_time, :end_time

    def initialize(issue, start_time, end_time)
        self.issue = issue
        self.start_time = start_time
        self.end_time = end_time
    end

end
