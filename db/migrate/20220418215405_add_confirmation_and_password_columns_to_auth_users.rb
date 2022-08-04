class AddConfirmationAndPasswordColumnsToAuthUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :auth_users, :confirmed_at, :datetime
    add_column :auth_users, :password_digest, :string, null: false
  end
end
