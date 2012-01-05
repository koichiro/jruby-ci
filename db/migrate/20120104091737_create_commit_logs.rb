class CreateCommitLogs < ActiveRecord::Migration
  def change
    create_table :commit_logs do |t|
      t.string :uri
      t.string :author
      t.string :title
      t.text :content
      t.string :link
      t.string :short_link
      t.boolean :posted

      t.timestamps
    end
  end
end
