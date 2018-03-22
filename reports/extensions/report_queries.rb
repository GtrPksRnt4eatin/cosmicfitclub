module Sinatra
  module ReportQueries

    def self.registered(app)
    
      app.get '/class_email_list' do
        JSON.generate ClassOccurrence.get_email_list(params[:from],params[:to],params[:classdef_ids])
      end
   
    end

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
end