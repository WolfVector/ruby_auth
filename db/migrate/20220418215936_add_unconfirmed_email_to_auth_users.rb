class AddUnconfirmedEmailToAuthUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :auth_users, :unconfirmed_email, :string
  end
end
