
class AddAuthModelsToDB < Sequel::Migration
  
  def up

  	create_table(:users) do
      primary_key :id
      String :name
      String :email 
    end

    create_table(:roles) do
      primary_key :id
  	  String :name
    end

    create_join_table(:user_id=>:users, :role_id=>:roles)

    create_table(:omniaccounts) do
  	  primary_key :id
  	  String :provider
  	  String :provider_id
  	  String :photo_url
  	  foreign_key :user_id, :users
    end 

  end

  def down
    drop_table(:users, :roles, :roles_users, :omniaccounts)
  end
 
end