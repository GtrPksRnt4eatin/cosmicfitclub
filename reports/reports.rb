require 'sinatra/base'

class Reports < Sinatra::Base

  enable :sessions	
  set :root, File.dirname(__FILE__)

  helpers  Sinatra::ViewHelpers
  register Sinatra::PageFolders
  register Sinatra::SharedResources
  register Sinatra::Auth

  get( '/pass_balances', )                  { render_page :index }
  get( '/pass_balances', :auth => 'admin' ) { render_page :pass_balances }

  def pass_balances
  	$DB["
      SELECT
        customers.id,
        stripe_id,
        name,
        email,
        wallet_id,
        pass_balance
      FROM customers
      LEFT JOIN wallets on wallet_id = wallets.id
      WHERE pass_balance > 0
      ORDER BY pass_balance DESC;
    "].all
  end

end