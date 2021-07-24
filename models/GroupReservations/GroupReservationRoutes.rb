class GroupReservationRoutes < Sinatra::Base

  before do
    cache_control :no_store
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