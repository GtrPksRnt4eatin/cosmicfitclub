$(document).ready( function() {
  
  var binding = rivets.bind( $('body'), { data: data } );
  var stripe  = Stripe(STRIPE_PUBLIC_KEY);

});