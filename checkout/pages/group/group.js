data = {
  reservation: {}
}

$(document).ready( function() {
  include_rivets_dates();
  include_rivets_money();

  $.get('/models/groups/' + reservation_id)
   .then(function(val) {
     console.log(val);
     data.reservation = val;
   })

   rivets.bind( $('body'), { data: data });
});