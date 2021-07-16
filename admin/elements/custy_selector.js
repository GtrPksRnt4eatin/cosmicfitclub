function CustySelector(parent) {
  
  this.state = { 
    customers: [],
    customer_id: 0,
    show_add_form: false,
    new_customer_name: "",
    new_customer_email: ""
  }

  this.bind_handlers(['get_custy_list','on_data','on_data_failed','edit_customer','new_customer','custy_selected','select_customer','init_selectize','show_add_form']);
  this.build_dom();
  this.mount(parent);
  this.load_styles();
  this.bind_dom();

  this.init_selectize();
  this.get_custy_list();
}

CustySelector.prototype = {
  constructor: CustySelector,

  get_custy_list: function() {
    return $.get('/models/customers/list')
            .fail(this.on_data_failed)
            .done(this.on_data);
  },

  on_data: function(list) {
    this.state.customers = list.map(function(val){ val['list_string'] = ( val.name || val.email ) + " ( " + val.email + " )"; return val; });
    this.selectize_instance.selectize.clear();
    this.selectize_instance.selectize.clearOptions();
    this.selectize_instance.selectize.renderCache['option'] = {};
    this.selectize_instance.selectize.renderCache['item'] = {};
    this.selectize_instance.selectize.addOption(this.state.customers);
    if(this.state.customer_id) { this.select_customer(this.state.customer_id) }
  },

  init_selectize: function() {
    var el = $(this.dom).find('select.customers');
    this.selectize_instance = el.selectize({
      options: this.state.customers,
      valueField: 'id',
      labelField: 'list_string',
      searchField: 'list_string',
    })[0];
    $(el).next().on( 'click', function () {
      this.selectize_instance.selectize.clear(false);
      this.selectize_instance.selectize.focus();
    }.bind(this));
  },

  show_modal: function(customer_id, callback) {
    this.state.callback = null;
    this.select_customer(customer_id);
    this.state.callback = callback;
    this.ev_fire('show', { 'dom': this.modal_dom, 'position': 'modal'} );
  },

  on_data_failed: function() {
    console.log("failed getting customer list");
  },

  edit_customer: function(e,m) {
    window.location.href = '/frontdesk/customer_file?id=' + this.state.customer_id;
  },

  new_customer: function(e,m) {
    var name = prompt("Enter The New Customers Name:", "");
    var email = prompt("Enter The New Customers E-Mail:", "");
    $.post('/auth/register', JSON.stringify({
        "name": name,
        "email": email
      }), 'json')
     .fail( function(req,msg,status) { 
        alert('failed to create customer');
      })
     .success( function(data) {
        this.get_custy_list().then( function() { this.select_customer(data.id) }.bind(this));
      }.bind(this) );
  },

  select_customer: function(custy_id) {
    this.state.customer_id = custy_id;
    this.selectize_instance.selectize.setValue(custy_id);
  },

  custy_selected: function(e,m) {
    var id = parseInt(e.target.value || 0);
    this.ev_fire('customer_selected', id );
    if(id!=0) { 
      this.ev_fire('close_modal', null); 
      if( this.state.callback ) { this.state.callback.call(null,id); this.state.callback = null; }
    }
  },

  get modal_dom() {
    var el = document.createElement("div");
    el.className = 'modal_container';
    el.setAttribute("style", "display: inline-block; left: 0; right: 0; margin: auto; vertical-align: middle; background: rgb(100,100,100); padding: 1em; box-shadow: 0 0 0.5em white;");
    el.appendChild(this.dom);
    return el;
  },

  get selected_customer() {
    return this.state.customers.find( function(val) { return val.id == this.state.customer_id; }.bind(this) );
  },

  show_add_form: function(e,m) {
    this.state.show_add_form = true;
  }
}

Object.assign( CustySelector.prototype, element);
Object.assign( CustySelector.prototype, ev_channel); 

CustySelector.prototype.HTML =  ES5Template(function(){/**
  <div class='custy_selector'>
    <div>
      <select class='customers' placeholder='Search Existing Customers...' rv-on-change='this.custy_selected' rv-value='this.state.customer_id'></select>
      <img class='edit_custy' rv-unless="this.state.show_add_form" rv-on-click='this.edit_customer' src='/person.svg'>
      <div class='add_custy'  rv-unless="this.state.show_add_form" rv-on-click='this.new_customer'>
        <span>+</span>
      </div>
    </div>
    <div rv-if='this.state.show_add_form'>
      <h3>Register New Customer</h3>
      <input placeholder='New Customer Name' rv-value='this.state.new_customer_name'></input>
      <input placeholder='New Customer Email' rv-value='this.state.new_customer_email'></input>
    </div>
  </div>
**/}).untab(2);

CustySelector.prototype.CSS = ES5Template(function(){/**
  .custy_selector {
    display: flex;
  }

  .modal_container .custy_selector {
    width: 30em;
  }

  .custy_selector .customers {
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

  @media (orientation: portrait) {
    .modal_container .custy_selector {
      font-size: 2.8vw;
    }
  }

**/}).untab(2);