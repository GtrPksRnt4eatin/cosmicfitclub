class GroupReservationRoutes < Sinatra::Base

  before do
    cache_control :no_store
    content_type :json
  end

  get '/gcal_events' do
    Calendar::get_day_events(params[:day]).to_json
  end

  post '/' do
    data = JSON.parse(request.body.read)

    res = GroupReservation.create(
      :start_time          => data['start_time'],
      :end_time            => data['end_time'],
      :customer_id         => data['customer_id'],
      :activity            => data['activity'],
      :note                => data['note'],
      :is_lesson           => data['is_lesson']
    )

    data['slots'].each do |slot|
      res.add_slot(
        :customer_id          => (slot['customer_id']==0 ? nil : slot['customer_id']),
        :start_time           => data['start_time'],
        :duration_mins        => data['duration_mins']
      )
    end

    res.send_slack_notification
    res.send_confirmation_emails
    res.to_public_daypilot.to_json
  end

  get '/my_upcoming' do
    content_type :json
    GroupReservationSlot.where(:customer_id=>session[:customer_id]).where(:start_time => Date.today..nil).all.map(&:reservation).map(&:to_token).to_json
  end

  get '/:id' do
    res = GroupReservation[params[:id]] or halt(404, "Reservation Not Found")
    res.details_view.to_json
  end

  delete '/:id' do
    res = GroupReservation[params[:id]] or halt(404, "Reservation Not Found")
    res.full_delete
    {}.to_json
  end

  #################################### GROUP RESERVATION LISTS ##############################

  get '/range/:from/:to' do
    content_type :json
    GroupReservation.all_between(params[:from], params[:to]).map { |res| 
      res.to_public_daypilot(session[:customer_id])
    }.to_json
  end

  get '/range-admin/:from/:to' do
    content_type :json
    GroupReservation.all_between(params[:from], params[:to]).map(&:to_admin_daypilot).to_json
  end

  #################################### GROUP RESERVATION LISTS ##############################

  post '/gcal_updates' do

  end

  error do
    puts "ERRORRRRRRRR!!!!!!!!"
    Slack.err( 'Group Reservation Route Error', env['sinatra.error'] )
    'An Error Occurred.'
  end

end
