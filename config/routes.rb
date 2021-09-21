get    'issues/:id/occurrences/:date/edit',  :to => 'occurrences#edit', :as => :edit_issue_occurrence
put    'issues/:id/occurrences/:date',       :to => 'occurrences#update', :as => :issue_occurrence
delete 'issues/:id/occurrences/:date',       :to => 'occurrences#destroy'
delete 'issues/:id/occurrences/:date/reset', :to => 'occurrences#reset', :as => :reset_issue_occurrence
