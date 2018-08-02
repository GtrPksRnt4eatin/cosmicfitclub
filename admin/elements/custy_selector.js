function CustySelector(parent,list) {
  
  this.state = { 
    customers: empty(list) ? [] : list,
    customer_id: 0
  }

  this.bind_handlers(['get_custy_list','on_data','on_data_failed','edit_customer','new_customer','custy_selected']);
  this.build_dom();
  this.mount(parent);
  this.load_styles();
  this.bind_dom();

  if(empty(list)) { this.get_custy_list(); }

}

CustySelector.prototype = {
  constructor: CustySelector,

  get_custy_list: function() {
    $.get('/models/customers/list')
     .fail(this.on_data_failed)
     .done(this.on_data);
  },

  on_data: function(list) {
    this.state.customers = list;
  },

  on_data_failed: function() {
    console.log("failed getting customer list");
  },

  edit_customer: function(e,m) {
    window.location.href = '/checkout/customer_file?id=' + this.state.customer_id;
  },

  new_customer: function(e,m) {
    var x = 5;
  },

  custy_selected: function(e,m) {
    this.ev_fire('customer_selected', this.selected_customer );
  },

  get selected_customer() {
    return this.state.customers.find( function(val) { return val.id == this.state.customer_id; } );
  }
}

Object.assign( CustySelector.prototype, element);
Object.assign( CustySelector.prototype, ev_channel); 

CustySelector.prototype.HTML =  ES5Template(function(){/**
  <div class='custy_selector'>
    <select class='customers' rv-select='state.customers' rv-value='state.customer_id' rv-on-change='this.custy_selected'>
      <option value='0'>No Customer</option>
      <option rv-each-cust='state.customers' rv-value='cust.id'>
        { cust.name } ( { cust.email } )
      </option>
    </select>
    <img class='edit_custy' rv-on-click='this.edit_customer' src='/person.svg'>
    <div class='add_custy'  rv-on-click='this.new_customer'>
      <span>+</span>
    </div>
  </div>
**/}).untab(2);

CustySelector.prototype.CSS = ES5Template(function(){/**
  .custy_selector {
    display: flex;	
  }

  .custy_selector .chosen-container {
    flex: 1;
  }

  .custy_selector .add_custy,
  .custy_selector .edit_custy {
    height: 1.92em;
    flex: 0 0 1.92em;
    margin-left: 0.5em;
    background: rgba(168,181,191,0.9);
    border-radius: 0.4em;
    cursor: pointer;
  }

  .custy_selector .edit_custy {
    vertical-align: middle; 
  }

  .custy_selector .add_custy {
    display: inline-block; 
    vertical-align: middle;
    line-height: 1.92em;
    color: #647585;
  }

  .custy_selector .add_custy span {
    font-size: 2em;
    display: inline-block;
    font-weight: bold;
  }

**/}).untab(2);