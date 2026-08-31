class GroupReservationRoutes < Sinatra::Base

  before do
    cache_control :no_store
    content_type :json
  end

  get '/gcal_events' do
    Calendar::get_day_events(params[:day]).to_json
  end

  # Kiosk: returns all aerial point reservations in a window around now
  get '/aerial_window' do
    now  = Time.now
    from = now - 2 * 3600
    to   = now + 8 * 3600
    reservations = GroupReservation.all_between(from, to)
                     .select { |r| r.resource_id == 1 }
                     .map(&:details_view)
    reservations.to_json
  end

  # Kiosk: look up a customer by email (for pass payment identification)
  get '/customer_lookup' do
    halt 400, "Email required" unless params[:email]
    custy = Customer.find_by_email(params[:email]) or halt 404, "No account found"
    { id: custy.id, name: custy.name, num_passes: custy.num_passes }.to_json
  end

  # Kiosk: check in a slot and record payment
  post '/slots/:id/checkin' do
    slot = GroupReservationSlot[params[:id].to_i] or halt 404, "Slot not found"
    res  = slot.reservation

    passes_per_hour = 1
    passes_needed   = (res.duration_hr * passes_per_hour).to_i
    cents_per_hour  = 1200
    amount_cents    = passes_needed * cents_per_hour

    if params[:payment_type] == 'passes'
      custy = slot.customer || (params[:customer_id] && Customer[params[:customer_id].to_i])
      halt 404, "No customer identified for pass payment" unless custy
      halt 402, "Insufficient passes (need #{passes_needed}, have #{custy.num_passes.to_i})" if custy.num_passes < passes_needed

      custy.rem_passes(passes_needed, "Aerial Point: #{res.summary}", "")
      payment = CustomerPayment.create(
        :customer  => custy,
        :stripe_id => nil,
        :amount    => amount_cents,
        :reason    => "Aerial Point: #{res.summary}",
        :type      => 'passes',
        :tag       => 'rental'
      )
      slot.update(payment_id: payment.id, customer_id: custy.id)

    elsif params[:payment_id]
      payment = CustomerPayment[params[:payment_id].to_i] or halt 404, "Payment not found"
      slot.update(payment_id: payment.id)

    else
      halt 400, "payment_type 'passes' or payment_id required"
    end

    # Record checkin
    existing = GroupReservationCheckin.where(slot_id: slot.id).first
    GroupReservationCheckin.create(slot_id: slot.id) unless existing

    Slack.website_purchases("Aerial Kiosk Checkin: #{slot.customer.try(:name) || 'Guest'} — #{res.summary}")
    slot.details_view.to_json
  end

  post '/' do
    data = JSON.parse(request.body.read)
    resource_id = data['resource_id'] || 1

    halt(409, "Conflicting Reservation Found") if GroupReservation.check_for_conflict(data['start_time'], data['end_time'], resource_id)

    res = GroupReservation.create(
      :start_time          => data['start_time'],
      :end_time            => data['end_time'],
      :customer_id         => data['customer_id'],
      :activity            => data['activity'],
      :note                => data['note'],
      :is_lesson           => data['is_lesson'],
      :resource_id         => resource_id
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
    halt 401, "Not Logged In" unless session[:customer_id]
    owned = GroupReservation.where(:customer_id=>session[:customer_id]).where(:start_time => Date.today..nil).all
    participating = GroupReservationSlot.where(:customer_id=>session[:customer_id]).where(:start_time => Date.today..nil).all.map(&:reservation)
    (owned+participating).uniq.map(&:to_token).to_json
  end

  get '/:id' do
    res = GroupReservation[params[:id]] or halt(404, "Reservation Not Found")
    res.details_view.to_json
  end

  put '/:id' do
    res  = GroupReservation[params[:id]] or halt(404, "Reservation Not Found")
    data = JSON.parse(request.body.read)

    new_start = Time.parse(data['start_time']) if data['start_time']
    new_end   = Time.parse(data['end_time'])   if data['end_time']

    if new_start && new_end
      conflict = GroupReservation.check_for_conflict(new_start, new_end, res.resource_id)
      halt(409, "Conflicting Reservation Found") if conflict && conflict.id != res.id
    end

    res.update(
      start_time: new_start || res.start_time,
      end_time:   new_end   || res.end_time,
      activity:   data['activity'] || res.activity,
      note:       data.key?('note') ? data['note'] : res.note,
      is_lesson:  data.key?('is_lesson') ? data['is_lesson'] : res.is_lesson
    )

    # Update slot times to match
    res.slots.each { |s| s.update(start_time: res.start_time, duration_mins: res.duration_min) }

    res.details_view.to_json
  end

  post '/:id/slots' do
    res  = GroupReservation[params[:id]] or halt(404, "Reservation Not Found")
    data = JSON.parse(request.body.read)
    custy_id = data['customer_id'].to_i
    custy_id = nil if custy_id == 0
    slot = res.add_slot(
      customer_id:   custy_id,
      start_time:    res.start_time,
      duration_mins: res.duration_min
    )
    slot.details_view.to_json
  end

  patch '/slots/:slot_id' do
    slot = GroupReservationSlot[params[:slot_id].to_i] or halt(404, "Slot Not Found")
    data = JSON.parse(request.body.read)
    custy_id = data['customer_id'].to_i
    slot.update(customer_id: custy_id == 0 ? nil : custy_id)
    slot.details_view.to_json
  end

  delete '/:id/slots/:slot_id' do
    res  = GroupReservation[params[:id]]      or halt(404, "Reservation Not Found")
    slot = GroupReservationSlot[params[:slot_id].to_i] or halt(404, "Slot Not Found")
    halt(403, "Slot does not belong to this reservation") unless slot.group_reservation_id == res.id
    slot.checkin.delete if slot.checkin
    slot.delete
    res.publish_gcal_event
    {}.to_json
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
    cal_update = request.env.select { |k,v| k.include? "HTTP_X_GOOG" }
    changes = Calendar::fetch_changes(cal_update) or return
    Slack.post(changes)
    changes.each { |change| GroupReservation.update_from_gcal(change) }
    status 204
  end

  error do
    puts "ERRORRRRRRRR!!!!!!!!"
    Slack.err( 'Group Reservation Route Error', env['sinatra.error'] )
    'An Error Occurred.'
  end

end
