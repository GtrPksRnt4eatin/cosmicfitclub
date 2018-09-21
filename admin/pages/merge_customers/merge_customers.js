ctrl = {
  load_custy1(e,m) {
  	data.custy1_id = this.value || data.custy1_id;
    $.get('/models/customers/' + data.custy1_id + '/fulldetails', function(custy) {
      data.custy1 = custy;
    }, 'json');
  },

  load_custy2(e,m) {
  	data.custy2_id = this.value || data.custy2_id;
    $.get('/models/customers/' + data.custy2_id + '/fulldetails', function(custy) {
      data.custy2 = custy;
    }, 'json');
  },

  merge_left(e,m) {
    $.post('/models/customers/' + data.custy2_id + '/merge_into/' + data.custy1_id, function() { ctrl.load_custy1(); ctrl.load_custy2(); });
  },

  merge_right(e,m) {
    $.post('/models/customers/' + data.custy1_id + '/merge_into/' + data.custy2_id, function() { ctrl.load_custy1(); ctrl.load_custy2(); });
  },

  del_custy1(e,m) {
    $.del('/models/customers/' + data.custy1_id, function() { data.custy1_id = 0; data.custy1 = {}; })
     .fail( function() { alert('delete failed')});
  },

  del_custy2(e,m) {
    $.del('/models/customers/' + data.custy2_id, function() { data.custy2_id = 0; data.custy2 = {}; })
     .fail( function() { alert('delete failed')});
  }
}

$(document).ready(function() {

  userview = new UserView(id('userview_container'));

  include_rivets_select();
  include_rivets_dates();
  
  rivets.formatters.plan_name = function(val) { 
    var plan = data.plans.find(function(x) { return x.id == val; });
    if(plan) { return plan.name; }
    return '???';
  }

  rivets.bind(document.body, { data: data, ctrl: ctrl } );

});