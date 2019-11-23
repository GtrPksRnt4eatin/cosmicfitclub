function TicketSelector(parent) {

  this.state = { 
    event_id: 0,
    event: null,
    event_sessions: [],
    event_tickets: [],
    customer: null,
    a_la_carte: [],
    a_la_carte_price: 0
  }

  this.bind_handlers([ 'select_price', 'load_customer', 'on_payment', 'on_sess_click', 'buy_a_la_carte', 'on_payment_a_la_carte' ]);
  this.parent = parent;
  this.build_dom();
  this.mount(parent);
  rivets.formatters.sess_selected = function(val) { return this.state.a_la_carte.indexOf(val) }
  this.bind_dom();
  this.load_styles();

}

TicketSelector.prototype = {

  constructor: TicketSelector,

  load_event: function(event_id) {
    $.get('/models/events/' + event_id)
     .done( function(evt) { this.state.event = evt; }.bind(this) )
     .fail( function()    { alert('Failed to load Event' + event_id); } )
  },

  load_event_data: function(event) {
  	this.state.event = event;
  },

  load_customer: function(customer_id) {

    if(customer_id==0) { this.state.customer = null; this.state.subscription = null; return; }

    $.get('/models/customers/' + customer_id)
     .done( function(custy) { this.state.customer = custy; }.bind(this) )
     .fail( function()    { alert('Failed to load Customer: ' + customer_id); } )

    $.get('/models/customers/' + customer_id + '/subscription')
     .done( function(subsc) { this.state.subscription = subsc; }.bind(this) )
     .fail( function()      { alert('Failed to load Subscriptions: ' + customer_id); } )

  },

  load_customer_data: function(customer) {
    this.state.customer = customer;
  },

  select_price: function(e,m) {
    if( empty(this.state.customer) ) { alert('Select A Customer First'); return; }
    this.state.selected_price = m.price;
    this.ev_fire('paynow', [ this.state.customer.id, this.price, this.state.event.name + ": " + m.price.title, null, this.on_payment ] );
  },

  on_payment: function(payment_id){
    var payload = {
      customer_id:       this.state.customer.id, 
      event_id:          this.state.event.id,
      included_sessions: this.state.selected_price.included_sessions,
      total_price:       this.price,
      payment_id:        payment_id,
      price_id:          this.state.selected_price.id
    }

    $.post('/checkout/event/precharged', payload )
     .success( function() { alert("Ticket Created"); this.ev_fire('ticket_created'); }.bind(this) )
     .fail( function(e) { alert("Failed Creating Ticket"); } )
  },

  on_payment_a_la_carte: function(payment_id){
    var payload = {
      customer_id:       this.state.customer.id, 
      event_id:          this.state.event.id,
      included_sessions: this.state.a_la_carte.map(function(el) { return el.id; } ),
      total_price:       this.price,
      payment_id:        payment_id,
      price_id:          null
    }

    $.post('/checkout/event/precharged', payload )
     .success( function() { alert("Ticket Created"); this.ev_fire('ticket_created'); }.bind(this) )
     .fail( function(e) { alert("Failed Creating Ticket"); } )
  },

  on_sess_click: function(e,m) {
    var index = this.state.a_la_carte.indexOf(m.sess);
    if (index === -1) { this.state.a_la_carte.push(m.sess); }
    else              { this.state.a_la_carte.splice(index, 1); }
  },

  buy_a_la_carte: function(e,m) {
    if( empty(this.state.customer) ) { alert('Select A Customer First'); return; }
    this.ev_fire('paynow', [ this.state.customer.id, this.price, this.state.event.name + ": Custom Ticket", null, this.on_payment_a_la_carte ] );
  },

  get price() {
    if( this.state.event.a_la_carte ) {
      if( this.member ) { return this.state.a_la_carte.reduce( function(tot, record) { return tot + record.individual_price_member; }, 0); }
      else              { return this.state.a_la_carte.reduce( function(tot, record) { return tot + record.individual_price_full;   }, 0); }
    }
    return ( this.member ? this.state.selected_price.member_price : this.state.selected_price.full_price );
  },

  get member() {
    return !!this.state.subscription;
  }

}

Object.assign( TicketSelector.prototype, element);
Object.assign( TicketSelector.prototype, ev_channel); 

TicketSelector.prototype.HTML = ES5Template(function(){/**
  <div class='ticket_selector'>

    <div class='price' rv-each-price='state.event.prices' rv-on-click='this.select_price' rv-title='price.id'> 
      <span>{price.title}</span>
      <span rv-if='state.subscription'>     Member Price: {price.member_price | money} </span>
      <span rv-unless='state.subscription'> Full Price: {price.full_price | money}     </span>
    </div>

    <div class='alacarte' rv-if='state.event.a_la_carte'>
      <div>Build Your Own Ticket</div>
      <div rv-each-sess='state.event.sessions'>
        <span rv-class='sess | sess_selected'>
          <span class='clickable' rv-on-click='this.on_sess_click'> { sess.title } </span>
        </span>
      </div>
      <div>
        <button rv-on-click='this.buy_a_la_carte'>Check Out</button>
      </div>
    </div>

  </div>
**/}).untab(2);

TicketSelector.prototype.CSS = ES5Template(function(){/**
  .ticket_selector {
	  padding: 1em;
    box-shadow: 0 0 3px white;
  }

  .ticket_selector .price {
    padding: 0.5em;
    background: rgba(255,255,255,0.1);
    margin: 0.2em;
    cursor: pointer;
  }

  .ticket_selector .price span {
    display: inline-block;
    width: 13em;
  }

  .ticket_selector .clickable {
    cursor: pointer;
  }

  .ticket_selector .clickable::hover {
    background: rgba(255,255,255,0.1);
  }

**/}).untab(2);
