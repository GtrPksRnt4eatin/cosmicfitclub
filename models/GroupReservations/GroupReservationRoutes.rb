class GroupReservationRoutes < Sinatra::Base

  before do
    cache_control :no_store
  end

  post '/' do
    data = JSON.parse(request.body.read)

    res = GroupReservation.create(
      :start_time          => data['start_time'],
      :end_time            => data['end_time'],
      :customer_id         => data['customer_id'],
      :is_lesson           => data['is_lesson']
    )

    data['slots'].each do |slot|
      GroupReservationSlot.create(
        :group_reservation_id => res.id,
        :customer_id          => (slot['customer_id']==0 ? nil : slot['customer_id']),
        :start_time           => data['start_time'],
        :duration_mins        => data['duration_mins'],
      )
  end

  #################################### GROUP RESERVATION LISTS ##############################

  get '/range/:from/:to' do
    content_type :json
    GroupReservation.all_between(params[:from], params[:to]).map(&:to_public_daypilot).to_json
  end

  get '/range-admin/:from/:to' do
    content_type :json
    GroupReservation.all_between(params[:from], params[:to]).map(&:to_admin_daypilot).to_json
  end

  #################################### GROUP RESERVATION LISTS ##############################

  error do
    Slack.err( 'Group Reservation Route Error', env['sinatra.error'] )
    'An Error Occurred.'
  end

end