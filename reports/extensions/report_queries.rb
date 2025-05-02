module Sinatra
  module ReportQueries

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
        WHERE fractional_balance > 0
        ORDER BY fractional_balance DESC;
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

    def attendence(from,to)
      from ||= "2017-01-01"
      to ||= Date.today
      $DB["
        SELECT array_to_json(array_agg(row_to_json(r2))) FROM (
          SELECT
            max(classdef_id) AS class_id,
            max(classdef_name) AS class_name,
            sum(count) AS total_visits,
            count(class_occurrence_id) AS occurrences_count,
            avg(count) AS average_attendence,
            array_agg(json_build_object('staff_id', staff_id, 'staff_name', staff_name, 'starttime',starttime,'headcount',count)) AS occurrences_list
          FROM (
            SELECT 
              max(classdef_id) AS classdef_id, 
              max(classdef_name) AS classdef_name, 
              max(staff_id) AS staff_id,
              max(staff_name) AS staff_name,
              class_occurrence_id,
              starttime,
              count(class_reservation_id)
            FROM class_reservations_details
            GROUP BY class_occurrence_id, starttime
          ) AS r1
          WHERE starttime > ?
          AND starttime <= ?
          GROUP BY classdef_id
        ) AS r2
      ",from,to].all[0][:array_to_json]
    end

    def self.registered(app)

      app.get '/class_email_list' do
        JSON.generate ClassOccurrence.get_email_list(params[:from],params[:to],params[:classdef_ids])
      end

      app.get '/class_email_list.csv' do
        content_type 'application/csv'
        attachment "Email List.csv"
        p params[:classdef_ids]
        p params[:classdef_ids].is_a? Array
        classdef_ids = [params[:classdef_ids].to_i] unless params[:classdef_ids].is_a? Array
        classdef_ids ||= params[:classdef_ids].map(&:to_i)
        p classdef_ids
        list = ClassOccurrence.get_email_list(params[:from],params[:to],classdef_ids)
        CSV.generate do |csv|
          csv << ["#{params[:from]} - #{params[:to]}", classdef_ids.map { |id| ClassDef[id].name }.join(' ,') ]
          csv << ["Customer ID", "Customer Name", "Email", "Visits"]
          list.each { |x| csv << [ x[:customer_id], x[:customer_name], x[:customer_email], x[:num_visits] ] }
        end
      end

      app.get '/attendence_list.json' do
        JSON.generate attendence(params[:from], params[:to])
      end

    end

  end
end