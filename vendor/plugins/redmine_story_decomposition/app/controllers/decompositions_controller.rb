class DecompositionsController < ApplicationController
  class DecompositionException < RuntimeError; end
  
  unloadable
  
  before_filter :find_issue_and_project, :authorize
  
  def index
  end
  
  def new
    render :partial => 'issue', :object => Issue.new
  end
  
  def create
    task_tracker = @project.trackers.find_by_name('Task')

    @issues = []
    @new_issues = []
    
    Issue.transaction do
      Array(params[:issue]).each do |key, value|
        if 'new' == key.to_s
          value.each do |attrs|
            issue = @project.issues.create(attrs.merge(:tracker_id => task_tracker.id, :author => User.current))
            @issues << issue
            @new_issues << issue
          end
        else
          issue = Issue.find(key)
          issue.update_attributes(value)
          @issues << issue
        end
      end

      @issues.each {|issue| issue.save }
      @new_issues.each do |issue|
        IssueRelation.create(:issue_to_id => issue.id, :issue_from_id => @issue.id, :relation_type => 'composes')
      end
    end
    
    raise DecompositionException unless @issues.all?(&:valid?)
    
    redirect_to :action => 'index', :id => @issue.id
  rescue DecompositionException => exception
    render :action => 'index'
  end
  
private
  def find_issue_and_project
    @issue = Issue.find(params[:id])
    @project = @issue.project
  end
end