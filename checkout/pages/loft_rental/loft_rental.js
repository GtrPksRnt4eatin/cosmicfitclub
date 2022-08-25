data = {
  rental: {
    starttime: '',
    endtime: '',
    activity: '',
    note: '',
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
  }
}

$(document).ready( function() {
  include_rivets_dates();

  rivets.formatters.equals    = function(val, arg) { return val == arg; }
  rivets.formatters.fix_index = function(val, arg) { return val + 1; }

  var binding = rivets.bind( $('body'), { data: data, ctrl: ctrl } );

  userview       = new UserView(id('userview_container'));
  popupmenu      = new PopupMenu( id('popupmenu_container') );
  //loft_calendar  = new LoftCalendar(id('loft_calendar_container'));
  loft_calendar = get_element(view,'loft-calendar');
  custy_selector = new CustySelector();

  custy_selector.ev_sub('show'       , popupmenu.show );
  custy_selector.ev_sub('close_modal', popupmenu.hide );

  loft_calendar.ev_sub('on_timeslot_selected', function(val) {
    console.log(val);

  });
  
  //loft_calendar.build_daypilot();
});

function on_timeslot_selected(args) {
  if(!userview.logged_in) { userview.onboard(); return;  }
  data.selected_timeslot.starttime = new Date(args.start.value);
  data.selected_timeslot.endtime = new Date(data.selected_timeslot.starttime.getTime() + 60 * 60 * 1000)
  data.num_slots = 2;
  data.rental.slots = [];
  data.rental.slots.push( { customer_id: userview.id, customer_string: userview.custy_string } );
  data.rental.slots.push( { customer_id: 0, customer_string: "Add Student" } );
  calculate_total();
}

