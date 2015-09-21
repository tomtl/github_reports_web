class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :provider, null: false   # Which service is this user for? For this project, it will always be 'github'.
      t.string :remote_id, null: false  # The user's ID as provided by GitHub.
      t.string :name, null: false       # The user's name or username for display in the application's UI.
      t.string :token, null: false      # The access token resulting from the OAuth authorization process.

      t.timestamps null: false
    end
  end
end
