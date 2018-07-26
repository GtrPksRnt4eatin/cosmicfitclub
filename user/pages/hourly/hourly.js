$(document).ready(function() {
  
  userview = new UserView( id('userview_container'));

  $('#punch_in').click( function() {
  
  })

  $('#punch_out').click( function() {

  })

}

function get_shifts() {
  $.get('/models/hourly/shifts', { customer_id: } )
}