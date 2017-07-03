function PaymentForm() {

  this.state = {
    price: 0,
    reason: '',
    customer: {},
    token: null,
    metadata: {},
    callback: null,
    polling: false,
    poll_request: null,
    swipe: null,
    swipe_source: null
  }

  this.bind_handlers(['failed_charge', 'charge_token', 'charge_swiped', 'on_swipe', 'poll_for_swipe', 'start_polling','stop_polling', 'on_customer', 'on_card_change', 'show', 'show_err', 'on_card_token', 'charge_new', 'after_charge']);
  this.build_dom();
  this.load_styles();
  this.bind_dom();

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

  rivets.formatters.empty = function(val) { 
    return ( val ? val.length==0 : true ); 
  }

}

PaymentForm.prototype = {
  constructor: PaymentForm,

  checkout(customer_id, price, reason, metadata, callback)  {
    this.state.price = price;
    this.state.reason = reason;
    this.state.metadata = metadata;
    this.state.callback = callback;
    this.get_customer(customer_id).done(this.show);
    this.show_err(null);
    this.stop_polling();
    this.start_polling();
  },

  poll_for_swipe() {
    if( !this.state.polling ) return;
    this.state.poll_request = $.get('https://cosmicfitclub.com/checkout/wait_for_swipe', 'json')
     .done( this.on_swipe )
     .fail( this.poll_for_swipe )
  },

  start_polling() {
    if(this.state.swipe_source) return;  
    this.state.swipe_source = new EventSource('/checkout/wait_for_swipe');
    this.state.swipe_source.addEventListener('swipe', this.on_swipe);
  },

  stop_polling() {
    if(!this.state.swipe_source) return;
    this.state.swipe_source.close();
    this.state.swipe_source = null;
  },

  on_swipe(e) {
    this.state.swipe = JSON.parse(e.data);
  },

  get_customer(id) {
    this.state.customer = null;
    return $.get("/models/customers/" + id, this.on_customer, 'json')
     .fail( function(e) { alert('failed getting payment sources!'); })  
  },

  on_customer(customer) { this.state.customer = customer; },

  on_card_change(e) {
    this.show_err( e.error );
    if( !e.complete ) { return; }
    stripe.createToken(this.card).then(this.on_card_token);
  },

  on_card_token(result) {
    this.show_err(result.error);
    this.state.token = result.token;
  },

  show_err(err) {
    var displayError = $(this.dom).find('#card-errors')[0];
    if( err ) { displayError.textContent = err.message; }
    else      { displayError.textContent = '';          }
  },

  show() {
    this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} );
    this.card.mount('#card-element');
  },

  charge_saved(e,m) {
    this.stop_polling();
    body = { customer: this.state.customer.id, card: m.card.id, amount: this.state.price, description: this.state.reason };
    $.post('/checkout/charge_saved_card', body, this.after_charge, 'json').fail( this.failed_charge );
  },

  charge_new() {
    this.charge_token(this.state.token.id)
  },

  charge_swiped() {
    this.charge_token(this.state.swipe_id)
  },

  charge_token(token_id) {
    this.stop_polling();
    if(!token_id) return;
    body = { customer: this.state.customer.id, token: token_id, amount: this.state.price, description: this.state.reason };
    $.post('/checkout/charge_card', body, this.after_charge, 'json').fail( this.failed_charge );
  },

  pay_cash() {
    this.stop_polling();
    body = { customer: this.state.customer.id, amount: this.state.price, reason: this.state.reason }
    $.post('/checkout/pay_cash', body, this.after_charge, 'json').fail( this.failed_charge );
  },

  failed_charge(e) {
    alert('Failed Charge');
  },

  after_charge(payment) {
    this.state.callback(payment.id);
    this.ev_fire('hide');
  }
}

Object.assign( PaymentForm.prototype, element);
Object.assign( PaymentForm.prototype, ev_channel); 

PaymentForm.prototype.HTML = `

  <div class='PaymentForm form' >
    <h2>Charging { state.customer.name } { state.price | money }</h2>
    <h3>{ state.reason }</h3>
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
      <tr>
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

`.untab(2);

PaymentForm.prototype.CSS = `

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

`.untab(2);
