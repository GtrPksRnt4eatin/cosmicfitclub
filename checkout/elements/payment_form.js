function PaymentForm() {

  this.state = {
    price: 0,
    reason: '',
    customer: {},
    token: null,
    metadata: {},
    callback: null
  }

  this.bind_handlers(['on_customer', 'on_card_change', 'show', 'show_err', 'on_card_token', 'charge_new', 'after_charge']);
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
  },

  get_customer(id) {
    this.state.customer = null;
    return $.get("/models/customers/" + id, this.on_customer, 'json')
     .fail( function(e) { alert('failed getting payment sources!'); })  
  },

  on_customer(customer) { console.log(1); this.state.customer = customer; },

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
    console.log(2)
    this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} );
    this.card.mount('#card-element');
  },

  charge_new() {
    if(!this.state.token) return;
    body = { customer: this.state.customer.id, token: this.state.token.id, amount: this.state.price, description: this.state.reason, metadata: this.state.metadata };
    $.post('/checkout/charge_card', body, this.after_charge, 'json')
     .fail( function(e) {
        alert('Failed to Charge Card!'); 
      });
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
      <tr>
        <th>Saved Card</th>
        <td>
          <div class='saved_card' rv-each-card='state.customer.payment_sources'>
            <span> <input type='radio'> </span>
            <span> { card.brand } </span>
            <span> **** **** **** { card.last4 } </span>
            <span> { card.exp_month }/{ card.exp_year }
          </div>
        </td>
      </tr>
      <tr>
        <th>New Card</th>
        <td> 
          <div id='card-element'></div> 
        </td>
      </tr>
      <tr>
        <td colspan='2'>
          <div id='card-errors'></div>
        </td>
      <tr>
        <th></th>
        <td colspan='2'>
          <div id='card-errors'></div>
        </td>
      </tr>
      <tr>
        <th></th>
        <td>
          <button id='checkout' rv-on-click='this.charge_new'> Submit Payment </button>
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

`.untab(2);
