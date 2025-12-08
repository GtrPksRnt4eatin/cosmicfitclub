data = {
    rental: {
      start_time: '',
      end_time: '',
      activity: '',
      note: '',
      customer_id: null,
      is_lesson: false,
      slots: [],
      resource_id: 2 // Loft 1F Back
    },
    selected_timeslot: null,
    num_slots: 0,
    my_reservations: [],
    class_passes: 0
  };
  
  var daypilot;
  
  $(document).ready( function() {
    include_rivets_dates();
  
    rivets.formatters.equals    = function(val, arg) { return val == arg; }
    rivets.formatters.fix_index = function(val, arg) { return val + 1; }
  
    view = rivets.bind( $('body'), { data: data } );
  
    userview          = new UserView(id('userview_container'));
    popupmenu         = new PopupMenu( id('popupmenu_container') );
    loft_calendar     = get_element(view,'loft-calendar');
    reservations_list = get_element(view,'reservations-list');
    custy_selector    = new CustySelector();

    custy_selector.ev_sub('show'       , popupmenu.show );
    custy_selector.ev_sub('close_modal', popupmenu.hide );
  
    loft_calendar.ev_sub('on_timeslot_selected', function(val) {
      if(!userview.logged_in) { userview.onboard(); return;  }
      data.rental.customer_id = userview.id;
      let start = new Date(val.start.value);
      let end   = new Date( Math.max( start.getTime() + 3600000, new Date(val.end.value).getTime()));
      //data.selected_timeslot = { start: start, end: end };
      data.rental.start_time = start;
      data.rental.end_time = end;
      data.num_slots = 1;
      data.rental.slots = [];
      data.rental.slots.push( { customer_id: userview.id, customer_string: userview.custy_string } );
    });  
    
    userview.ev_sub('on_user', function() {
      $.get(`/models/customers/${userview.id}/class_passes`, function(resp) { data.class_passes = isNaN(resp) ? 0 : resp; }, 'json');
    });
  
    $.get('/models/groups/my_upcoming', function(resp) { data.my_reservations.splice(0, data.my_reservations.length, ...resp); }, 'json');
  
  });
  