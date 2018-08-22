var data = {
  rentals: [],
  past_rentals: []
}

var ctrl = {

  get: function() {
    $.get('/models/rentals', function(rentals) { data.rentals = rentals; }, 'json');
    $.get('/models/rentals/past', function(rentals) { data.past_rentals = rentals; }, 'json');
  },

  add: function(e,m) {
    rentalfrm.show_new();
  },

  edit: function(e,m) {
    rentalfrm.show_edit(m.rental);
  },

  del: function(e,m) {
    if(!confirm('really delete this rental?' + m.rental.title)) return;
    $.del('/models/rentals/' + m.rental.id)
     .done( function() { data['rentals'].splice(m.index,1); } );
  }

}

$(document).ready(function() {

  userview = new UserView(id('userview_container'));
  
  include_rivets_dates();

  rivets.bind(document.body, { data: data, ctrl: ctrl } );

  popupmenu   = new PopupMenu(id('popupmenu_container'));
  rentalfrm   = new RentalForm();

  rentalfrm.ev_sub('show', popupmenu.show );
  rentalfrm.ev_sub('after_post', function(rental) { ctrl.get(); popupmenu.hide(); });

  ctrl.get();

});