class AddIndexUriToCommitLogs < ActiveRecord::Migration
  def change
    add_index :commit_logs, :uri
  end
end
