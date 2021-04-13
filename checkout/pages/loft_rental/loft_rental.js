data = {
  rental: {
    starttime: '',
    endtime: '',
    activity: '',
    note: '',
  },
  num_slots: 0
};

ctrl = {
  set_num_slots: function(e,m) {
    data.num_slots = parseInt(e.target.value);
    data.num_slots = isNaN(data.num_slots) ? 0 : data.num_slots;
  },

  choose_custy: function(e,m) {
    custy_selector.choose_custy();
  }

}

$(document).ready( function() {

  include_rivets_dates();
  var binding = rivets.bind( $('body'), { data: data, ctrl: ctrl } );

  custy_selector = new CustySelector();

});