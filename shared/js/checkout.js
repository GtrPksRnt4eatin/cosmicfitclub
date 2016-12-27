var data = {
  
}

$(document).ready( function() {
        
  var handler = StripeCheckout.configure({
    zipCode: true,
    locale: 'auto',
    billingAddress: true,
    key: "#{ENV['STRIPE_PUBLIC']}",

    token: function(token) {
      data = {
        "type":  #{ params[:type] },
        "id":    #{ params[:id] },
        "token": token
      }
      $.post('/charge', JSON.stringify( data ) );
    }
  });

  id('checkout').addEventListener('click', function(e) {
    handler.open({
      name: 'Cosmic Fit Club',
      description: name(),
      image: 'https://cosmicfit.herokuapp.com/background2.jpg',
      amount: price()
    })
  });

  function price() {
    - if params[:type] == 'plan'
      return parseInt( "#{plan.full_price}" );
    - if params[:type] == 'package'
      return parseInt( "#{package.price}"   );
  }
  function name() {}
    if( "#{ params[:type] }" == "plan"    ) return parseInt( "#{plan.name}"    );
    if( "#{ params[:type] }" == "package" ) return parseInt( "#{package.name}" );
  }

});