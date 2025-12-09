data = {
    rental: {
      start_time: null,
      end_time: null,
      duration: 60,
      activity: 'other',
      note: '',
      customer_id: null,
      is_lesson: false,
      num_slots: 1,
      slots: [{ customer_id: null, customer_string: 'Click to Add Someone' }],
      resource_id: 2 // Loft 1F Back
    },
    class_passes: 0,
    my_reservations: []
  };
  
  $(document).ready( function() {
    include_rivets_dates();
  
    $.get('/models/groups/my_upcoming', function(resp) { data.my_reservations.splice(0, data.my_reservations.length, ...resp); }, 'json');

    view = rivets.bind( $('body'), { data: data } );
  
    userview          = new UserView(id('userview_container'));
    popupmenu         = new PopupMenu( id('popupmenu_container') );
    loft_calendar     = get_element(view,'loft-calendar');
    reservations_list = get_element(view,'reservations-list');
    group_timeslot    = get_element(view,'group-timeslot');
    custy_selector    = new CustySelector();

    userview.ev_sub('on_user', function() {
      $.get(`/models/customers/${userview.id}/class_passes`, function(resp) { data.class_passes = isNaN(resp) ? 0 : resp; }, 'json');
      data.rental.customer_id = userview.id;
      data.rental.slots.splice(0, data.rental.slots.length, { customer_id: userview.id, customer_string: userview.custy_string } );
    });

    custy_selector.ev_sub('show'       , popupmenu.show );
    custy_selector.ev_sub('close_modal', popupmenu.hide );
  
    loft_calendar.ev_sub('on_timeslot_selected', function(val) {
      if(!userview.logged_in) { userview.onboard(); return;  }
      group_timeslot.set_timeslot(new Date(val.start.value), new Date(val.end.value));
    });  
    
    group_timeslot.ev_sub('choose_customer', function(args) {
      custy_selector.show_modal( args['customer_id'], function(custy_id) {
        let customer_string = custy_selector.selected_customer.list_string;
        if(args.callback) { args.callback(custy_id, customer_string, args['index']); }
      } );
    });
    
  });
  