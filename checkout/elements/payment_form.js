function PaymentForm() {

  this.state = {
  }

  this.bind_handlers(['save']);
  this.build_dom();
  this.load_styles();
  this.bind_dom();
}

PaymentForm.prototype = {
  constructor: PaymentForm,

  show(price, reason)  { 
    this.state.sessions = data.event.sessions;
  	this.state.price = { "id": 0 };
  	this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} ); 
  }

  save(e) {
    $.post(`/models/events/${data['event'].id}/prices`, JSON.stringify(this.state.price), function(price) {
      this.ev_fire('after_post', JSON.parse(price) );
    }.bind(this));
  }
}

Object.assign( PaymentForm.prototype, element);
Object.assign( PaymentForm.prototype, ev_channel); 

PaymentForm.prototype.HTML = `

  <div class='PaymentForm'>
    <table>
      <tr>
        <th>Saved Cards</th>
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
        <th></th>
        <td colspan='2'>
          <div id='card-errors'></div>
        </td>
      </tr>
      <tr>
        <th></th>
        <td>
          <button id='checkout'> Submit Payment </button>
        </td>
      </tr>
    </table>
  </div>

`.untab(2);

PaymentForm.prototype.CSS = `

  .PaymentForm { }

`.untab(2);
