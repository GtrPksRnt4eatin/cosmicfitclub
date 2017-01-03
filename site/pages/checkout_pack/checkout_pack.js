      $(document).ready( function() {
        
        var handler = StripeCheckout.configure({
          zipCode: true,
          locale: 'auto',
          billingAddress: true,
          key: STRIPE_PUBLIC_KEY,

          token: function(token) {
            data = {
              "type":  "package",
              "plan_id": PACKAGE['id'],
              "token": token
            }

            $.post('/stripe/charge', JSON.stringify( data ) );
          }

        });

        id('checkout').addEventListener('click', function(e) {
          handler.open({
            name: 'Cosmic Fit Club',
            description: PACKAGE['name'],
            image: 'https://cosmicfit.herokuapp.com/background-blu.jpg',
            amount: PACKAGE['pass_price'] * PACKAGE['num_passes']
          })
        });

      });
