require 'sinatra/base'

class Reports < Sinatra::Base

  enable :sessions	
  set :root, File.dirname(__FILE__)

  helpers  Sinatra::ViewHelpers
  register Sinatra::PageFolders
  register Sinatra::SharedResources
  register Sinatra::Auth

  get( '/', )                               { render_page :index }
  get( '/pass_balances', :auth => 'admin' ) { render_page :pass_balances }
  get( '/subscriptions', :auth => 'admin' ) { render_page :subscriptions }

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

  def subscriptions
    $DB["
      SELECT 
        subscriptions.*,
        customers.name,
        customers.email,
        plans.name AS plan_name,
        plans.month_price,
        plans.term_months
      FROM subscriptions
      LEFT JOIN customers ON customers.id = customer_id
      LEFT JOIN plans ON plans.id = plan_id
      WHERE deactivated IS NOT true
      ORDER BY plan_id
    "].all
  end

end