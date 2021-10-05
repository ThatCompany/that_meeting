class OccurrencesController < ApplicationController
    menu_item :issues

    helper :issue_meetings

    before_action :find_issue
    before_action :find_exception, :except => :index
    before_action :authorize

    def index
        respond_to do |format|
            format.html { redirect_to issue_path(@issue, :date => params[:date]) }
            format.js
        end
    end

    def edit
        @exception.start_date ||= params[:date]
        unless @exception.start_time
            @exception.start_time = @issue.start_time
            @exception.end_time = @issue.end_time
        end
        @exception.init_journal(User.current)
    end

    def update
        @exception.init_journal(User.current)
        @exception.safe_attributes = params[:exception]
        if @exception.save
            flash[:notice] = l(:notice_successful_update)
            redirect_back_or_default issue_path(@issue, :date => @exception.date_param.beginning_of_month)
        else
            render :action => 'edit'
        end
    end

    def destroy
        @exception.init_journal(User.current)
        @exception.nullify
        @exception.save
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default issue_path(@issue, :date => @exception.date_param.beginning_of_month)
    end

    def reset
        @exception.init_journal(User.current)
        @exception.destroy
        respond_to do |format|
            format.html { redirect_back_or_default issue_path(@issue, :date => @exception.date_param.beginning_of_month) }
            format.js
        end
    end

private

    def find_exception
        if @issue.meeting?
            @exception = IssueMeetingException.where(:meeting => @issue.meeting).find_by_date_param(params[:date])
            if @exception.nil? && (date = (params[:date].to_date rescue nil)) && @issue.meeting.occurrences_between(date, date).any?
                @exception = IssueMeetingException.new(:meeting => @issue.meeting, :date => params[:date])
            end
        end
        render_404 unless @exception
    end

    def authorize
        allow_access = if action_name == 'index'
            User.current.allowed_to?(:view_issues, @project)
        else
            @issue.safe_attribute?('start_date')
        end
        allow_access || deny_access
    end

end
