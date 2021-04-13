data = {
  rental: {
    starttime: '',
    endtime: '',
    activity: '',
    note: '',
    slots: []
  },
  num_slots: 0
};

ctrl = {
  set_num_slots: function(e,m) {
    data.num_slots = parseInt(e.target.value);
    data.num_slots = isNaN(data.num_slots) ? 0 : data.num_slots;
    while(data.rental.slots.count<data.num_slots) {
      data.rental.slots.push({ }); 
    }
    while(data.rental.slots.count>data.num_slots){
      data.rental.slots.pop();
    }
  },

  choose_custy: function(e,m) {
    custy_selector.choose_custy();
  }

}

$(document).ready( function() {

  include_rivets_dates();
  rivets.formatters.equals = function(val, arg) { return val == arg; }
  var binding = rivets.bind( $('body'), { data: data, ctrl: ctrl } );


  custy_selector = new CustySelector();

});