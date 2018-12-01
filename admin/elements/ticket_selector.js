function TicketSelector(parent) {

  this.state = { 
    event_id: 0,
    event: null,
    event_sessions: [],
    event_tickets: [],
    customer: null
  }

  this.bind_handlers(['select_price']);
  this.parent = parent;
  this.build_dom();
  this.mount(parent);
  this.bind_dom();
  this.load_styles();

}

TicketSelector.prototype = {

  constructor: TicketSelector,

  load_event: function(event_id) {
    $.get('/models/events/' + event_id)
     .done( function(evt) { this.state.event = evt; } )
     .fail( function()    { alert('failed to load event' + event_id); } )
  },

  load_event_data: function(event) {
  	this.state.event = event;
  },

  load_customer: function(customer_id) {
    $.get('/models/customers/' + customer_id)
     .done( function(custy) { this.state.customer = custy; } )
     .fail( function()    { alert('failed to load customer' + customer_id); } )
  },

  load_customer_data: function(customer) {
    this.state.customer = customer;
  },

  select_price: function(e,m) {
    if( empty(this.state.customer) ) { alert('Select A Customer First'); return; }
    this.ev_fire('paynow', this.state.customer.id, m.price )
  }

}

Object.assign( TicketSelector.prototype, element);
Object.assign( TicketSelector.prototype, ev_channel); 

TicketSelector.prototype.HTML = ES5Template(function(){/**
  <div class='ticket_selector'>

    <div class='price' rv-each-price='state.event.prices' rv-on-click='this.select_price' rv-title='price.id'> 
      <span>{price.title}</span>
      <span>Member Price: {price.member_price | money}</span>
      <span>Full Price: {price.full_price | money}</span>
    </div>

    <div class='alacarte' rv-if='state.event.a_la_carte'>
      <div>Build Your Own Ticket</div>
      <div rv-each-sess='state.event.sessions'>
        <span> { sess.title } </span>
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
    width: 11em;
  }
**/}).untab(2);
