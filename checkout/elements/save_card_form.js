function SaveCardForm() {
  this.state = {
    customer_id: 0,
  	swipe_source: null
  }

  this.bind_handlers(['init_stripe', 'show', 'on_card_change', 'on_card_token', 'on_customer', 'on_cardswipe', 'start_listen_cardswipe','stop_listen_cardswipe','hide','save_entered','save_swiped']);
  this.build_dom();
  this.load_styles();
  this.bind_dom();
  this.init_stripe();
}

SaveCardForm.prototype = {
  constructor: SaveCardForm,

  init_stripe: function() {
    this.card = elements.create('card', { 
      hidePostalCode: true,
      style: {
        base: {
          lineHeight: '1.5em',
          fontFamily: '"Industry-Light", sans-serif',
          fontWeight: 'bold',
          fontSmoothing: 'antialiased',
          fontSize: '1em',
          '::placeholder': { color: '#aab7c4' }
        },
        invalid: {
          color: '#fa755a',
          iconColor: '#fa755a'
        }
      }
    });
    this.card.addEventListener('change', this.on_card_change);
  },

  get_new_card: function() {
    this.state.swipe = null;
    this.show_err(null);
    this.stop_listen_cardswipe();
    this.start_listen_cardswipe();
    this.show();
  },

  show: function() {
    this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} );
    this.card.mount('.SaveCardForm #card-element');
  },

  //////////////////////////// CARDSWIPE EVENT STREAM ///////////////////////////////
  
  start_listen_cardswipe: function() {
    if(this.state.swipe_source) return;  
    this.state.swipe_source = new EventSource('/checkout/wait_for_swipe');
    this.state.swipe_source.addEventListener('swipe', this.on_cardswipe);
  },

  stop_listen_cardswipe: function() {
    if(!this.state.swipe_source) return;
    this.state.swipe_source.close();
    this.state.swipe_source = null;
  },

  on_cardswipe: function(e) {
    this.state.swipe = JSON.parse(e.data);
  },

  //////////////////////////// CARDSWIPE EVENT STREAM ///////////////////////////////

  clear_customer: function() {
    this.state.customer = null;
  },

  get_customer: function(id) {
    this.clear_customer();
    this.state.customer_id = id;
    return $.get("/models/customers/" + id, this.on_customer, 'json')
            .fail( function(e) { console.log('failed getting payment sources!'); })  
  },

  on_customer: function(customer) { this.state.customer = customer; },

  on_card_change: function(e) {
    this.show_err( e.error );
    if( !e.complete ) { return; }
    stripe.createToken(this.card).then(this.on_card_token);
  },

  on_card_token: function(result) {
    this.show_err(result.error);
    this.state.token = result.token;
  },

  show_err: function(err) {
    var displayError = $(this.dom).find('#card-errors')[0];
    if( err ) { displayError.textContent = err.message; }
    else      { displayError.textContent = '';          }
  },

  save_entered: function(e,m) {
    $.post('/checkout/save_card', { token: this.state.token, customer_id: this.state.customer.id } )
     .success( function() { alert('Card Saved'); } )
     .fail( function() { alert('Card Not Saved'); } )
     .then( this.hide )
  },

  save_swiped: function(e,m) {
    $.post('/checkout/save_card', { token: this.state.swipe, customer_id: this.state.customer.id } )
     .success( function() { alert('Card Saved'); } )
     .fail( function() { alert('Card Not Saved'); } )
     .then( this.hide )
  },

  hide: function() {
    this.ev_fire('hide');
  }

}

Object.assign( SaveCardForm.prototype, element);
Object.assign( SaveCardForm.prototype, ev_channel); 

SaveCardForm.prototype.HTML = ES5Template(function(){/**

  <div class='SaveCardForm form' >
    <h2 class='nocusty'>Charging { state.customer.name } { state.price | money }</h2>
    <h2 class='custy'>Pay { state.price | money } now.</h2>
    <h3 rv-if='state.reason'>{ state.reason }</h3>
    <table>
      <tr rv-if='state.swipe' >
        <th>Swiped Card</th>
        <td>
          <div class='saved_card'>
            <span> { state.swipe.card.brand } </span>
            <span> **** **** **** { state.swipe.card.last4 } </span>
            <span> { state.swipe.card.exp_month }/{ state.swipe.card.exp_year }
          </div>
        </td>
        <td>
          <button rv-on-click='this.save_swiped'> Save Card </button>
        </td>
      </tr>
      <tr>
        <th>New Card</th>
        <td> 
          <div id='card-element'></div> 
        </td>
        <td>
          <button rv-on-click='this.save_entered' > Save Card </button>
        </td>
      </tr>
      <tr>
        <td.nopadding colspan='2'>
          <div id='card-errors'></div>
        </td>
      </tr> 
    </table>
  </div>

**/}).untab(2);

SaveCardForm.prototype.CSS = ES5Template(function(){/**

  .SaveCardForm { 
    display: inline-block;
    background: rgb(100,100,100);
  }

  .SaveCardForm table td:nth-child(2) {
    width: 30em;
  }

  .SaveCardForm td.nopadding {
    padding: 0;
  }

  .SaveCardForm .card-errors {
    padding: .5em;
  }

  .SaveCardForm .cash,
  .SaveCardForm .saved_card {
    border: 1px solid white;
    padding: .5em;
    border-radius: 4px;
    box-shadow: 0 1px 3px 0 #e6ebf1;
    display: flex;
    justify-content: space-around;
  }

  .SaveCardForm button {
    padding: .5em;
    cursor: pointer;
    border-radius: 4px;
  }

  .SaveCardForm td,
  .SaveCardForm th {
    padding: .5em;
  }

  .SaveCardForm .StripeElement {
    background-color: white;
    padding: 8px 12px;
    border-radius: 4px;
    border: 1px solid transparent;
    box-shadow: 0 1px 3px 0 #e6ebf1;
    -webkit-transition: box-shadow 150ms ease;
    transition: box-shadow 150ms ease;
  }

  .SaveCardForm #card-errors {
    font-size: .8em;
    color: rgb(255,80,80);
    text-shadow: 0 0 0.5em black;
  }

  .SaveCardForm:not(.custy_facing) .custy {
    display: none;
  }

  .SaveCardForm.custy_facing .nocusty {
    display: none;
  }

  .SaveCardForm.custy_facing .custy {
    display: initial;
  }

  @media(max-width: 800px) {
    .SaveCardForm.custy_facing {
      width: 90vw;
      font-size: 3vw;
    }
  }

**/}).untab(2);