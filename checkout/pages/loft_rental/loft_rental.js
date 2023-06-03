data = {
  rental: {
    start_time: '',
    end_time: '',
    activity: '',
    note: '',
    customer_id: null,
    is_lesson: false,
    slots: []
  },
  selected_timeslot: null,
  num_slots: 0
};

var daypilot;

ctrl = {
  set_num_slots: function(e,m) {
    data.num_slots = parseInt(e.target.value);
    data.num_slots = isNaN(data.num_slots) ? 0 : data.num_slots;
    while(data.rental.slots.length<data.num_slots) {
      data.rental.slots.push({ customer_id: 0, customer_string: '' }); 
    }
    while(data.rental.slots.length>data.num_slots){
      data.rental.slots.pop();
    }
  },

  choose_custy: function(e,m) {
    custy_selector.show_modal(m.slot.customer_id, function(custy_id) {
      m.slot.customer_id = custy_id;
      m.slot.customer_string = custy_selector.selected_customer.list_string;
      alert(custy_id);
    } );
  },
  
  request_slot: function(e,m) {
    $.post('/models/groups', JSON.stringify( data.rental ) )
      .done(function() {
        window.location.href = '/checkout/complete';
      })
      .fail(function(e) {
        alert(e.status);
      });
  }
}

$(document).ready( function() {
  include_rivets_dates();

  rivets.formatters.equals    = function(val, arg) { return val == arg; }
  rivets.formatters.fix_index = function(val, arg) { return val + 1; }

  var view = rivets.bind( $('body'), { data: data, ctrl: ctrl } );

  userview       = new UserView(id('userview_container'));
  popupmenu      = new PopupMenu( id('popupmenu_container') );
  loft_calendar  = get_element(view,'loft-calendar');
  custy_selector = new CustySelector();

  custy_selector.ev_sub('show'       , popupmenu.show );
  custy_selector.ev_sub('close_modal', popupmenu.hide );

  loft_calendar.ev_sub('on_timeslot_selected', function(val) {
    if(!userview.logged_in) { userview.onboard(); return;  }
    data.rental.customer_id = userview.id();
    data.selected_timeslot = { start: new Date(val.start.value), end: new Date(val.end.value) };
    data.rental.start_time = new Date(val.start.value);
    data.rental.end_time = new Date(val.end.value);
    data.num_slots = 1;
    data.rental.slots = [];
    data.rental.slots.push( { customer_id: userview.id, customer_string: userview.custy_string } );
    calculate_total();
  });

});

//function on_timeslot_selected(args) {
//  if(!userview.logged_in) { userview.onboard(); return;  }
//  data.selected_timeslot.starttime = new Date(args.start.value);
//  data.selected_timeslot.endtime = new Date(data.selected_timeslot.starttime.getTime() + 60 * 60 * 1000)
//  data.num_slots = 2;
//  data.rental.slots = [];
//  data.rental.slots.push( { customer_id: userview.id, customer_string: userview.custy_string } );
//  data.rental.slots.push( { customer_id: 0, customer_string: "Add Student" } );
//  calculate_total();
//}

