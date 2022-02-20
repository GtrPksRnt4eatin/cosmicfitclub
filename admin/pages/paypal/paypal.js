data = {
    range: "",
    transactions: [],
    from: "",
    to: ""
  }

ctrl = {}


$(document).ready(function() {

  userview = new UserView(id('userview_container'));

  include_rivets_dates();
  include_rivets_money();

  rivets.bind( document.body, { data: data, ctrl: ctrl } );

});