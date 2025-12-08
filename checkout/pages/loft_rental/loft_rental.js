data = {
  rental: {
    start_time: '',
    duration: 60,
    end_time: '',
    activity: '',
    note: '',
    customer_id: null,
    is_lesson: false,
    num_slots: 1,
    slots: [],
    resource_id: 1 // Loft 1F Front
  },
  selected_timeslot: null,
  class_passes: 0,
  num_slots: 0,
  my_reservations: []
};

var daypilot;

ctrl = {
  set_num_slots: function(e,m) {
    data.rental.num_slots = parseInt(e.target.value);
    data.rental.num_slots = isNaN(data.rental.num_slots) ? 0 : data.rental.num_slots;
    while(data.rental.slots.length<data.rental.num_slots) {
      data.rental.slots.push({ customer_id: 0, customer_string: '' }); 
    }
    while(data.rental.slots.length>data.rental.num_slots){
      data.rental.slots.pop();
    }
  },

  add_slot: function(e,m) {
    if(data.num_slots == 4) { return; }
    if(isNaN(data.num_slots)) { return; }
    data.num_slots = data.num_slots + 1;
    data.rental.slots.push({ customer_id: 0, customer_string: '' });
  },

  choose_custy: function(e,m) {
    custy_selector.show_modal(m.slot.customer_id, function(custy_id) {
      m.slot.customer_id = custy_id;
      m.slot.customer_string = custy_selector.selected_customer.list_string;
    } );
  },
  
  request_slot: function(e,m) {
    $.post('/models/groups', JSON.stringify( data.rental ) )
     .done(function()  { window.location.reload(); })
     .fail(function(e) { alert(`${e.status} - ${e.responseText}`); });
  },

  clear_starttime: function(e,m) {
    data.selected_timeslot = null;
  },

  update_endtime: function(e,m) {
    data.rental.end_time = new Date(data.rental.start_time.getTime() + data.rental.duration * 60000);
  },

  cancel: function(e,m) {
    if(!confirm("Are you sure you want to cancel?")) { return; }
    $.del(`/models/groups/${m.reservation.id}`)
     .done(function() { window.location.reload(); });
  }

}

$(document).ready( function() {
  include_rivets_dates();

  rivets.formatters.equals    = function(val, arg) { return val == arg; }
  rivets.formatters.fix_index = function(val, arg) { return val + 1; }

  $.get('/models/groups/my_upcoming', function(resp) { data.my_reservations.splice(0, data.my_reservations.length, ...resp); }, 'json');

  view = rivets.bind( $('body'), { data: data, ctrl: ctrl } );

  userview          = new UserView(id('userview_container'));
  popupmenu         = new PopupMenu( id('popupmenu_container') );
  loft_calendar     = get_element(view,'loft-calendar');
  reservations_list = get_element(view,'reservations-list');
  group_timeslot    = get_element(view,'group-timeslot');
  custy_selector    = new CustySelector();

  userview.ev_sub('on_user', function() {
    $.get(`/models/customers/${userview.id}/class_passes`, function(resp) { data.class_passes = resp.length==0 ? 0 : resp; }, 'json');
  });

  custy_selector.ev_sub('show'       , popupmenu.show );
  custy_selector.ev_sub('close_modal', popupmenu.hide );

  rivets.formatters.empty = function(reservations) { 
    return reservations.length == 0;
  }

  loft_calendar.ev_sub('on_timeslot_selected', function(val) {
    if(!userview.logged_in) { userview.onboard(); return;  }
    data.rental.customer_id = userview.id;
    let start = new Date(val.start.value);
    let end   = new Date( Math.min( Math.max( start.getTime() + 3600000, new Date(val.end.value).getTime()), start.getTime() + 14400000 ) );
    data.selected_timeslot = { start: start, end: end };
    data.rental.start_time = start;
    data.rental.end_time = end;
    data.rental.duration = Math.round((end.getTime() - start.getTime()) / 60000);
    data.num_slots = 1;
    data.rental.slots = [];
    data.rental.slots.push( { customer_id: userview.id, customer_string: userview.custy_string } );
  });

  group_timeslot.ev_sub('choose_customer', function(args) {
    custy_selector.show_modal( args['customer_id'], function(custy_id) {
      let customer_string = custy_selector.selected_customer.list_string;
      if(args.callback) { args.callback(custy_id, customer_string, args.index); }
    } );
  });

});
