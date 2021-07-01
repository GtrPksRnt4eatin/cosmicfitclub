function PaymentForm() {

  this.state = {
    customer_id: 0,
    price: 0,
    reason: '',
    customer: {},
    token: null,
    metadata: {},
    callback: null,
    poll_request: null,
    swipe: null,
    swipe_source: null,
    busy: false
  }

  this.bind_handlers(['init_stripe', 'checkout', 'pay_cash', 'charge_saved', 'clear_customer', 'failed_charge', 'charge_token', 'charge_swiped', 'on_cardswipe', 'start_listen_cardswipe','stop_listen_cardswipe', 'on_customer', 'on_card_change', 'show', 'show_err', 'on_card_token', 'charge_new', 'after_charge']);
  this.build_dom();
  this.load_styles();
  this.bind_dom();
  this.init_stripe();
}

PaymentForm.prototype = {
  constructor: PaymentForm,

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

  checkout: function(customer_id, price, reason, metadata, callback)  {
    this.state.customer_id = customer_id;
    this.state.price       = price;
    this.state.reason      = reason;
    this.state.metadata    = metadata;
    this.state.callback    = callback;
    this.state.swipe       = null;
    if(customer_id) { this.get_customer(customer_id).done(this.show).fail( function() { this.clear_customer(); this.show(); }.bind(this) ) }
    else            { this.clear_customer(); this.show(); }
    this.show_err(null);
    this.stop_listen_cardswipe();
    this.start_listen_cardswipe();
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

  on_card_change(e) {
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

  show: function() {
    this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} );
    this.card.mount('#card-element');
  },

  charge_saved: function(e,m) {
    if(this.state.busy) return;
    this.state.busy = true;
    this.stop_listen_cardswipe();
    body = { customer: this.state.customer_id, card: m.card.id, amount: this.state.price, description: this.state.reason };
    $.post('/checkout/charge_saved_card', body, this.after_charge, 'json').fail( this.failed_charge );
  },

  charge_new: function() {
    if(this.state.busy) return;
    this.state.busy = true;
    this.charge_token(this.state.token.id)
  },

  charge_swiped: function() {
    if(this.state.busy) return;
    this.state.busy = true;
    this.charge_token(this.state.swipe.id)
  },

  charge_token: function(token_id) {
    if(this.state.busy) return;
    this.state.busy = true;
    this.stop_listen_cardswipe();
    if(!token_id) return;
    body = { customer: this.state.customer_id, token: token_id, amount: this.state.price, description: this.state.reason };
    $.post('/checkout/charge_card', body, this.after_charge, 'json').fail( this.failed_charge );
  },

  pay_cash: function() {
    this.stop_listen_cardswipe();
    body = { customer: this.state.customer_id, amount: this.state.price, description: this.state.reason }
    $.post('/checkout/pay_cash', body, this.after_charge, 'json').fail( this.failed_charge );
  },

  failed_charge: function(e) {
    this.state.busy = false;
    $(this.dom).shake();
    e.message = e.responseText;
    this.show_err(e);
  },

  after_charge: function(payment) {
    this.state.busy = false;
    this.state.callback(payment.id);
    this.ev_fire('hide');
  },

  customer_facing: function() {
    $(this.dom).addClass('custy_facing');
  }
}

Object.assign( PaymentForm.prototype, element);
Object.assign( PaymentForm.prototype, ev_channel); 

PaymentForm.prototype.HTML = ES5Template(function(){/**

  <div class='PaymentForm form' >
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
          <button rv-on-click='this.charge_swiped'> Pay Now </button>
        </td>
      </tr>
      <tr rv-each-card='state.customer.payment_sources'>
        <th>Saved Card</th>
        <td>
          <div class='saved_card'>
            <span> { card.brand } </span>
            <span> **** **** **** { card.last4 } </span>
            <span> { card.exp_month }/{ card.exp_year }
          </div>
        </td>
        <td>
          <button rv-on-click='this.charge_saved'> Pay Now </button>
        </td>
      </tr>
      <tr>
        <th>New Card</th>
        <td> 
          <div id='card-element'></div> 
        </td>
        <td>
          <button rv-on-click='this.charge_new' > Pay Now </button>
        </td>
      </tr>
      <tr>
        <td.nopadding colspan='2'>
          <div id='card-errors'></div>
        </td>
      </tr> 
      <tr class='nocusty'>
        <th>Cash</th>
        <td>
          <div class='cash'>
            { state.price | money }
          </div>
        </td>
        <td>
          <button rv-on-click='this.pay_cash'> Pay Now </button>
        </td>
      </tr>
    </table>
  </div>

**/}).untab(2);

PaymentForm.prototype.CSS = ES5Template(function(){/**

  .PaymentForm { 
    display: inline-block;
    background: rgb(100,100,100);
  }

  .PaymentForm table td:nth-child(2) {
    width: 30em;
  }

  .PaymentForm td.nopadding {
    padding: 0;
  }

  .PaymentForm .card-errors {
    padding: .5em;
  }

  .PaymentForm .cash,
  .PaymentForm .saved_card {
    border: 1px solid white;
    padding: .5em;
    border-radius: 4px;
    box-shadow: 0 1px 3px 0 #e6ebf1;
    display: flex;
    justify-content: space-around;
  }

  .PaymentForm button {
    padding: .5em;
    cursor: pointer;
    border-radius: 4px;
  }

  .PaymentForm td,
  .PaymentForm th {
    padding: .5em;
  }

  .PaymentForm .StripeElement {
    background-color: white;
    padding: 8px 12px;
    border-radius: 4px;
    border: 1px solid transparent;
    box-shadow: 0 1px 3px 0 #e6ebf1;
    -webkit-transition: box-shadow 150ms ease;
    transition: box-shadow 150ms ease;
  }

  .PaymentForm #card-errors {
    font-size: .8em;
    color: rgb(255,80,80);
    text-shadow: 0 0 0.5em black;
  }

  .PaymentForm:not(.custy_facing) .custy {
    display: none;
  }

  .PaymentForm.custy_facing .nocusty {
    display: none;
  }

  .PaymentForm.custy_facing .custy {
    display: initial;
  }

  @media(max-width: 800px) {
    .PaymentForm.custy_facing {
      width: 90vw;
      font-size: 3vw;
    }
  }

**/}).untab(2);
