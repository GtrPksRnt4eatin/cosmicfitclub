ctrl = {
  load_custy1(e,m) {
    custy_selector.show_modal(0, function(custy_id) {
      data.custy1_id = custy_id || data.custy1_id;
      ctrl.refresh_custy1();
    });
  },

  load_custy2(e,m) {
    custy_selector.show_modal(0, function(custy_id) {
      data.custy2_id = custy_id || data.custy2_id;
      ctrl.refresh_custy2();
    });
  },

  refresh_custy1(e,m) {
    $.get('/models/customers/' + data.custy1_id + '/fulldetails', function(custy) {
      data.custy1 = custy;
    }, 'json');
  },

  refresh_custy2(e,m) {
    $.get('/models/customers/' + data.custy2_id + '/fulldetails', function(custy) {
      data.custy2 = custy;
    }, 'json');
  },

  merge_left(e,m) {
    $.post('/models/customers/' + data.custy2_id + '/merge_into/' + data.custy1_id, function() { ctrl.refresh_custy1(); ctrl.refresh_custy2(); });
  },

  merge_right(e,m) {
    $.post('/models/customers/' + data.custy1_id + '/merge_into/' + data.custy2_id, function() { ctrl.refresh_custy1(); ctrl.refresh_custy2(); });
  },

  del_custy1(e,m) {
    $.del('/models/customers/' + data.custy1_id)
     .success(  function() { alert("customer deleted"); data.custy1_id = 0; data.custy1 = {}; } )
     .fail( function(resp) { alert("delete failed\r\n" + resp.responseText)});
  },

  del_custy2(e,m) {
    $.del('/models/customers/' + data.custy2_id)
     .success(  function() { alert("customer deleted"); data.custy2_id = 0; data.custy2 = {}; })
     .fail( function(resp) { alert("delete failed\r\n" + resp.responseText)});
  },

  del_wallet1(e,m) {
    var x = confirm("Really Force Delete?");
    if(!x) return;
    $.del('/models/passes/wallet/' + data.custy1.wallet.id);
  },

  del_wallet2(e,m) {
    var x = confirm("Really Force Delete?");
    if(!x) return;
    $.del('/models/passes/wallet/' + data.custy2.wallet.id);
  },

  del_waiver(e,m) {
    $.del('/models/customers/waivers/' + m.waiver.id)
     .success( function() { ctrl.load_custy1(); ctrl.load_custy2(); } )
     .fail( function(resp) { alert("delete failed\r\n" + resp.responseText)})
  }

}

$(document).ready(function() {

  userview = new UserView(id('userview_container'));
  popupmenu      = new PopupMenu(id('popupmenu_container'));
  custy_selector = new CustySelector();

  custy_selector.ev_sub('show'       , popupmenu.show );
  custy_selector.ev_sub('close_modal', popupmenu.hide );

  include_rivets_select();
  include_rivets_dates();
  include_rivets_money();
  
  rivets.formatters.plan_name = function(val) { 
    var plan = data.plans.find(function(x) { return x.id == val; });
    if(plan) { return plan.name; }
    return '???';
  }

  rivets.formatters.occ_link = function(val) { 
    return('/frontdesk/class_attendance/' + val);
  }

  rivets.formatters.waiver_img = function(val) { 
    return('/models/customers/waivers/' + val);
  }

  rivets.bind(document.body, { data: data, ctrl: ctrl } );

});