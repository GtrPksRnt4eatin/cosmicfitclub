function CustySelector(parent,list) {
  
  this.state = { 
    customers: empty(list) ? [] : list,
    selected_custy: null
  }

  this.bind_handlers(['get_custy_list','on_data_failed','on_data']);
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
    var x = 5;
  },

  on_data_failed: function() {
    alert("failed getting customer list");
  },

  edit_customer: function(e,m) {
    var x = 5;
  },

  new_customer: function(e,m) {
    var x = 5;
  }
}

Object.assign( CustySelector.prototype, element);
Object.assign( CustySelector.prototype, ev_channel); 

CustySelector.prototype.HTML =  ES5Template(function(){/**
  <div class='custy_selector'>
    <select rv-select='state.customers'></select>
    <select class='customers'>
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
	
  }
**/}).untab(2);