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
    payment_form      = new PaymentForm();
    loft_calendar     = get_element(view,'loft-calendar');
    reservations_list = get_element(view,'reservations-list');
    group_timeslot    = get_element(view,'group-timeslot');
    custy_selector    = new CustySelector();

    payment_form.customer_facing();
    payment_form.ev_sub('show', popupmenu.show);
    payment_form.ev_sub('hide', popupmenu.hide);
    
    $('.buy-button').on('click', function(e) {
      e.preventDefault();
      if (!userview.logged_in) { userview.onboard(); return; }
      
      const button = $(this);
      const type = button.data('type');
      const id = button.data('id');
      const name = button.data('name');
      const amount = button.data('amount');
      
      payment_form.checkout(userview.id, amount, name, { type: type, id: id }, 
        function(payment_id) { 
          completePurchase(type, id, payment_id);
        }
      );
    });

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

  function completePurchase(type, id, payment_id) {
    let endpoint = '/checkout/pack/buy';
    let data = { 
      payment_id: payment_id,
      customer_id: userview.id,
      pack_id: id
    };
    
    $.post(endpoint, data, 'json')
     .done(function() { 
       alert('Purchase successful! Your passes have been added.');
       window.location.reload(); 
     })
     .fail(function(e) { 
       alert('There was an error completing your purchase. Please contact support.'); 
       console.error(e); 
     });
  }
  