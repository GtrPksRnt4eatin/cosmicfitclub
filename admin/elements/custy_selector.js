function CustySelector(parent, load, show_title, show_edit, show_new, component) {

  this.state = { 
    customer_id: 0,
    new_customer_name: "",
    new_customer_email: "",
    show_add_form: false,
    show_title: (typeof show_title !== 'undefined') ? show_title : true,
    show_edit:  (typeof show_edit !== 'undefined') ? show_edit : true,
    show_new:   (typeof show_new !== 'undefined') ? show_new : true
  }

  load = (typeof load !== 'undefined') ? load : true;

  this.bind_handlers(['get_custy_list','on_data','on_data_failed','refresh_selectize','edit_customer','new_customer','custy_selected','select_customer','init_selectize', 'show_modal', 'show_add_form','create_customer']);

  component && (this.dom = parent);
  component && (this.this = this);
  !component && this.build_dom();
  !component && this.bind_dom(this);
  !component && this.mount(parent);
  
  this.load_styles();
  
  CustySelector.state.instances.push(this);

  this.init_selectize();

  if(load) { this.get_custy_list(); }
}

CustySelector.state = {
  customers: [],
  instances: []
}

CustySelector.get_list_string = function(id, not_found) {
  not_found = not_found ? not_found : ""; 
  custy = CustySelector.state.customers.find(function(val) { return val.id == id });
  return custy ? custy.list_string : not_found;
}

CustySelector.prototype = {
  constructor: CustySelector,

  get_custy_list: function() {
    return $.get('/models/customers/list')
            .fail(this.on_data_failed)
            .done(this.on_data);
  },

  on_data: function(list) {
    CustySelector.state.customers = list.map(function(val){ val['list_string'] = ( val.name || val.email ) + " ( " + val.email + " )"; return val; });
    CustySelector.state.instances.forEach(function(el) { el.refresh_selectize(); });
  },

  refresh_selectize() {
    this.selectize_instance.selectize.clear();
    this.selectize_instance.selectize.clearOptions();
    this.selectize_instance.selectize.renderCache['option'] = {};
    this.selectize_instance.selectize.renderCache['item'] = {};
    this.selectize_instance.selectize.addOption(CustySelector.state.customers);
    if(this.state.customer_id) { this.select_customer(this.state.customer_id, true) }
  },

  init_selectize: function() {
    var el = $(this.dom).find('select.customers');
    this.selectize_instance = el.selectize({
      options: this.state.customers,
      valueField: 'id',
      labelField: 'list_string',
      searchField: 'list_string',
      openOnFocus: false
    })[0];
    $(el).next().on( 'click', function () {
      this.selectize_instance.selectize.clear(false);
      this.selectize_instance.selectize.focus();
    }.bind(this));
  },

  show_modal: function(customer_id, callback) {
    this.state.callback = null;
    this.state.new_customer_name = null;
    this.state.new_customer_email = null;
    this.select_customer(customer_id);
    this.state.callback = callback;
    this.ev_fire('show', { 'dom': this.modal_dom, 'position': 'modal'} );
    this.selectize_instance.selectize.focus();
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

  create_customer: function(e,m) {
    $.post('/auth/register', JSON.stringify({
      "name": this.state.new_customer_name,
      "email": this.state.new_customer_email,
    }), 'json')
   .fail( function(req,msg,status) { 
      alert('failed to create customer' + msg);
    })
   .success( function(data) {
      this.get_custy_list().then( function() { this.select_customer(data.id) }.bind(this));
    }.bind(this) );
  },

  select_customer: function(custy_id, silent) {
    this.state.customer_id = custy_id;
    this.selectize_instance.selectize.setValue(custy_id, silent);
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
    el.setAttribute("style", "display: inline-block; left: 0; right: 0; margin: auto; vertical-align: middle; border-radius: 2em; background: rgb(50,50,50); padding: 1.5em; box-shadow: 0 0 1em grey inset;");
    el.appendChild(this.dom);
    return el;
  },

  get selected_customer() {
    if(!CustySelector.state.customers) { return false; }
    return CustySelector.state.customers.find( function(val) { return val.id == this.state.customer_id; }.bind(this) );
  },

  show_add_form: function(e,m) {
    this.state.show_add_form = true;
    this.state.show_new = false;
  }
}

Object.assign( CustySelector.prototype, element);
Object.assign( CustySelector.prototype, ev_channel); 

CustySelector.prototype.HTML =  `
  <div class='custy_selector'>
    <h3 rv-if='this.state.show_title'>Select an Existing Customer</h3>
    <div class='selector'>
      <select class='customers' placeholder='Search Existing Customers...' rv-on-change='this.custy_selected' rv-value='this.state.customer_id'></select>
      <img class='edit_custy' rv-if="this.state.show_edit" rv-on-click='this.edit_customer' src='/person.svg'>
      <img class="add_custy" rv-if="this.state.show_new" rv-on-click='this.new_customer' src='/add.svg'/>
    </div>
    <div class='add_form' rv-if='this.state.show_add_form'>
      <h3>Register New Customer</h3>
      <input placeholder='New Customer Name' rv-value='this.state.new_customer_name'></input>
      <input placeholder='New Customer Email' rv-value='this.state.new_customer_email'></input>
      <button rv-on-click='this.create_customer'>Register</button>
    </div>
  </div>
`.untab(2);

CustySelector.prototype.CSS = `
  .custy_selector .selector {
    display: flex;
  }

  .modal_container .custy_selector {
    width: 35em;
  }

  .custy_selector .customers {
    flex: 1;
  }

  .custy_selector .add_form {
    display: flex;
    flex-direction: column;
  }

  .custy_selector .add_form button {
    background: rgb(200,200,200);
  }

  .custy_selector .add_form input,
  .custy_selector .add_form button {
    text-align: center;
    border: none;
    font-size: 1.5em;
    padding: 0.8em 2em;
    border-radius: 0.3em;
    display: block;
    margin: 0 0 0.5em 0; 
    font-family: inherit;
  } 

  .custy_selector .add_form button {
    cursor: pointer;
  }

  .custy_selector .add_custy,
  .custy_selector .edit_custy {
    flex: 0;
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
    width: 100%;
    text-align: center;
    line-height: 1.2em;
  }

  .custy_selector .selectize-input,
  .custy_selector .selectize_input input {
    height: 100%;
  }

  .custy_selector .selectize-input {
    display: flex;
    align-items: center;
  }

  @media(max-width: 800px) {
  
    .custy_selector .add_custy,
    .custy_selector .edit_custy {
      height: auto;
    }

    .modal_container .custy_selector {
      font-size: 2.8vw;
      width: 85vw !important;
    }
  }

`.untab(2);

rivets.components['custy-selector'] = { 
  template:   function()        { return CustySelector.prototype.HTML; },
  initialize: function(el,attr) { 
    selector = new CustySelector(el,true,false,false,false,true);
    selector.ev_sub('customer_selected', function(id) { attr['onchange'] && attr['onchange'].call(null,selector.selected_customer); }) 
    return(selector);
  }
}
