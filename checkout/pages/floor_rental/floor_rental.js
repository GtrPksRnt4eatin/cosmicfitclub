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
    my_reservations: null
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
       .fail(function(e) { alert(e.status);          });
    },
  
    clear_starttime: function(e,m) {
      data.selected_timeslot = null;
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
  
    var view = rivets.bind( $('body'), { data: data, ctrl: ctrl } );
  
    userview       = new UserView(id('userview_container'));
    popupmenu      = new PopupMenu( id('popupmenu_container') );
    loft_calendar  = get_element(view,'loft-calendar');
    custy_selector = new CustySelector();
  
    custy_selector.ev_sub('show'       , popupmenu.show );
    custy_selector.ev_sub('close_modal', popupmenu.hide );
  
    loft_calendar.ev_sub('on_timeslot_selected', function(val) {
      if(!userview.logged_in) { userview.onboard(); return;  }
      data.rental.customer_id = userview.id;
      let start = new Date(val.start.value);
      let end   = new Date( Math.max( start.getTime() + 3600000, new Date(val.end.value).getTime()));
      data.selected_timeslot = { start: start, end: end };
      data.rental.start_time = start;
      data.rental.end_time = end;
      data.num_slots = 1;
      data.rental.slots = [];
      data.rental.slots.push( { customer_id: userview.id, customer_string: userview.custy_string } );
    });
  
    $.get('/models/groups/my_upcoming', function(resp) { data.my_reservations = resp.length==0 ? null : resp; }, 'json');
  
  });
  