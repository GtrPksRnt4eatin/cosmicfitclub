function PaymentSources(el, attr) {

  this.state = {
    attrib:   attr,
    sources:  { list: [], count: 0 },
    adding:   false,
    working:  false,
    error:    ''
  };

  this.bind_handlers([
    'load_customer', 'refresh',
    'on_payment_sources', 'set_default', 'remove_source',
    'show_add_form', 'hide_add_form', 'submit_new_card', 'on_card_added'
  ]);
  this.build_dom(el);
  this.load_styles();
  this.bind_dom();
  this._stripe_card = null;
  this._stripe      = null;

}

PaymentSources.prototype = {
  constructor: PaymentSources,

  load_customer: function(custy_id) {
    this.state.attrib.customer.id = custy_id;
    this.refresh();
  },

  refresh: function() {
    var self = this;
    $.get('/customers/' + this.state.attrib.customer.id + '/payment_sources', function(data) {
      self.state.sources.list  = data;
      self.state.sources.count = data.length;
    }, 'json');
  },

  on_payment_sources: function(val) {
    this.state.sources.list  = val;
    this.state.sources.count = val.length;
  },

  set_default: function(e, m) {
    var self = this;
    $.post('/customers/' + this.state.attrib.customer.id + '/cards/set_default',
      { source_id: m.source.id },
      function() { self.refresh(); },
      'json'
    );
  },

  remove_source: function(e, m) {
    if (!confirm('Remove this card?')) return;
    var self = this;
    $.del('/customers/' + this.state.attrib.customer.id + '/cards/' + m.source.id,
      function() { self.refresh(); }
    );
  },

  show_add_form: function() {
    var self = this;
    this.state.adding  = true;
    this.state.error   = '';
    // Mount Stripe card element lazily
    if (!this._stripe) {
      this._stripe = Stripe(STRIPE_PUBLIC_KEY);
    }
    if (!this._stripe_card) {
      var elements = this._stripe.elements();
      this._stripe_card = elements.create('card', {
        style: { base: { color: '#fff', '::placeholder': { color: '#aaa' } } }
      });
    }
    // Wait for DOM then mount
    setTimeout(function() {
      var mount = self.dom.querySelector('#card_element_mount');
      if (mount && !mount.children.length) self._stripe_card.mount(mount);
    }, 50);
  },

  hide_add_form: function() {
    this.state.adding = false;
    this.state.error  = '';
    if (this._stripe_card) { this._stripe_card.unmount(); this._stripe_card = null; }
  },

  submit_new_card: function() {
    var self = this;
    if (this.state.working) return;
    this.state.working = true;
    this.state.error   = '';
    this._stripe.createToken(this._stripe_card).then(function(result) {
      if (result.error) {
        self.state.error   = result.error.message;
        self.state.working = false;
        return;
      }
      $.post(
        '/customers/' + self.state.attrib.customer.id + '/cards',
        { 'token[id]': result.token.id, 'token[email]': self.state.attrib.customer.email },
        function() { self.on_card_added(); },
        'json'
      ).fail(function(xhr) {
        self.state.error   = xhr.responseText || 'Failed to save card.';
        self.state.working = false;
      });
    });
  },

  on_card_added: function() {
    this.state.working = false;
    this.state.adding  = false;
    this._stripe_card  = null;
    this.refresh();
  }

}

Object.assign( PaymentSources.prototype, element);
Object.assign( PaymentSources.prototype, ev_channel);

PaymentSources.prototype.HTML = ES5Template(function(){/**
  <div class='payment_sources'>

    <div class='source' rv-each-source='state.sources.list'>
      <span class='brand'>{ source.brand }</span>
      <span class='number'>**** **** **** { source.last4 }</span>
      <span class='expiry'>{ source.exp_month }/{ source.exp_year }</span>
      <span class='badge default_badge' rv-show='source.default'>Default</span>
      <span class='actions'>
        <button class='btn_setdefault' rv-unless='source.default' rv-on-click='this.set_default'>Set Default</button>
        <button class='btn_remove' rv-on-click='this.remove_source'>Remove</button>
      </span>
    </div>

    <div class='no_cards' rv-unless='state.sources.count'>
      No saved cards.
    </div>

    <div class='add_form' rv-show='state.adding'>
      <div id='card_element_mount' class='card_element_mount'></div>
      <div class='card_error' rv-show='state.error'>{ state.error }</div>
      <div class='add_actions'>
        <button class='btn_save' rv-on-click='this.submit_new_card' rv-attr-disabled='state.working'>{ state.working | working_label }</button>
        <button class='btn_cancel' rv-on-click='this.hide_add_form'>Cancel</button>
      </div>
    </div>

    <button class='btn_add_card' rv-unless='state.adding' rv-on-click='this.show_add_form'>+ Add New Card</button>

  </div>
**/});

PaymentSources.prototype.CSS = ES5Template(function(){/**
  .payment_sources .source {
    border: 1px solid rgba(255,255,255,0.2);
    padding: .6em .8em;
    border-radius: 4px;
    margin-bottom: .4em;
    display: flex;
    align-items: center;
    gap: .8em;
    flex-wrap: wrap;
  }

  .payment_sources .brand   { font-weight: bold; min-width: 60px; }
  .payment_sources .number  { flex: 1; letter-spacing: .05em; }
  .payment_sources .expiry  { color: #aaa; }
  .payment_sources .actions { margin-left: auto; display: flex; gap: .4em; }

  .payment_sources .default_badge {
    font-size: .75em;
    background: rgba(100,200,100,0.25);
    color: #8f8;
    border: 1px solid #8f8;
    border-radius: 3px;
    padding: .2em .5em;
  }

  .payment_sources .no_cards { color: #aaa; margin: .5em 0; }

  .payment_sources button {
    padding: .35em .8em;
    cursor: pointer;
    border-radius: 4px;
    border: 1px solid rgba(255,255,255,0.3);
    background: rgba(255,255,255,0.08);
    color: #fff;
    font-size: .85em;
  }
  .payment_sources button:hover { background: rgba(255,255,255,0.18); }
  .payment_sources .btn_remove  { border-color: rgba(255,100,100,0.5); color: #f99; }
  .payment_sources .btn_add_card {
    margin-top: .6em;
    background: rgba(100,180,255,0.12);
    border-color: rgba(100,180,255,0.4);
    color: #8cf;
  }

  .payment_sources .add_form {
    margin-top: .8em;
    border: 1px solid rgba(255,255,255,0.15);
    border-radius: 4px;
    padding: .8em;
  }
  .payment_sources .card_element_mount {
    background: rgba(255,255,255,0.06);
    border: 1px solid rgba(255,255,255,0.2);
    border-radius: 4px;
    padding: .6em .8em;
    margin-bottom: .6em;
  }
  .payment_sources .card_error { color: #f88; font-size: .85em; margin-bottom: .5em; }
  .payment_sources .add_actions { display: flex; gap: .5em; }
  .payment_sources .btn_save { background: rgba(100,200,100,0.15); border-color: rgba(100,200,100,0.4); color: #8f8; }

**/});

rivets.formatters.working_label = function(v) { return v ? 'Saving...' : 'Save Card'; };

rivets.components['payment_sources'] = {
  template:   function()        { return PaymentSources.prototype.HTML },
  initialize: function(el,attr) { return new PaymentSources(el,attr); }
}
