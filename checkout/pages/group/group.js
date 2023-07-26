data = {
  reservation: {}
}

$(document).ready( function() {
  $.get('/models/groups/' + reservation_id)
   .then(function(val) {
     console.log(val);
     data.reservation = val;
   })

   rivets.bind( $('body'), { data: data });
});