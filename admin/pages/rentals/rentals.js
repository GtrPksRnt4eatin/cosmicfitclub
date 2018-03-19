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

  },

  edit: function(e,m) {

  },

  del: function(e,m) {

  }

}

$(document).ready(function() {

   userview = new UserView(id('userview_container'));
  
   include_rivets_dates();

   rivets.bind(document.body, { data: data, ctrl: ctrl } );

   popupmenu   = new PopupMenu(id('popupmenu_container'));
   rentalfrm   = new RentalForm();

   rentalfrm.ev_sub('show', popupmenu.show );

   ctrl.get();

});