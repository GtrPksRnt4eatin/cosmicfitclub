data = {
  reservation: {}
}

$(document).ready( function() {
  $.get('/models/groups/' + reservation_id)
   .then(function(val) {
     console.log(val);
     data.reservations = val;
   })

   rivets.bind( $('body'), { data: data });
});