class CreateAuthUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :auth_users do |t|
      t.string :email, null: false

      t.timestamps
    end

    add_index :auth_users, :email, unique: true
  end
end
