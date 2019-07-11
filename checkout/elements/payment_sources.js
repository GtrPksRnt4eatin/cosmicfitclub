function PaymentSources(el, attr) {

  this.state = {
    attrib:  attr 
  	sources: []
  }

  this.bind_handlers(['load_customer','get_payment_sources','on_payment_sources']);
  this.build_dom(el);
  this.load_styles();
  this.bind_dom();
  this.init_stripe();
  
}

PaymentSources.prototype = {
  constructor: PaymentSources,

  load_customer: function(custy_id) {
    this.state.attrib.customer.id = custy_id;
  },

  get_payment_sources: function() {
    $.get('/customers/' + this.state.attrib.customer.id + '/payment_sources', on_payment_sources, 'json')
  },

  on_payment_sources: function(val) {
    this.state.sources = val;
  }

}

Object.assign( PaymentSources.prototype, element);
Object.assign( PaymentSources.prototype, ev_channel);

PaymentSources.prototype.HTML = ES5Template(function(){/**
  <div class='payment_sources'>
    <div class='source' rv-each-source='state.sources'>
      <span> { card.brand } </span>
      <span> **** **** **** { card.last4 } </span>
      <span> { card.exp_month }/{ card.exp_year } </span>
      <span rv-if='source.default'> Default </span>
      <button rv-unless='source.default' rv-on-click='this.set_default'>Set As Default</button>
      <button rv-on-click='this.remove_source'>Remove Source</button>
    </div>
  </div>
**/});

PaymentSources.prototype.CSS = ES5Template(function(){/**
  .payment_sources .source {
    border: 1px solid white;
    padding: .5em;
    border-radius: 4px;
    box-shadow: 0 1px 3px 0 #e6ebf1;
    display: flex;
    justify-content: space-around;
  }

  .payment_sources button {
    padding: .5em;
    cursor: pointer;
    border-radius: 4px;
  }

  .payment_sources span {
    padding: .5em;
  }


**/});

rivets.components['payment_sources'] = {
  template:   function()        { return PaymentSources.prototype.HTML },
  initialize: function(el,attr) { return new PaymentSources(el,attr); }
}
