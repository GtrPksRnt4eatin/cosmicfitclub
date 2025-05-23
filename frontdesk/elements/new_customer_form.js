function NewCustomerForm(el, attr, build_dom) {

  this.dom  = el;
  this.attr = attr;

  this.load_styles();
  this.bind_handlers([]);
  if(this.dom == null) {
    this.build_dom();
    this.bind_dom();
  }
}

NewCustomerForm.prototype = {
  constructor: NewCustomerForm,

  show: function() {
    this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} );
  }

}

Object.assign( NewCustomerForm.prototype, element );
Object.assign( NewCustomerForm.prototype, ev_channel );

NewCustomerForm.prototype.HTML = ES5Template(function(){ /**
  <div class='new_customer_form'>
    <div class='form_title'>Create a New Customer</div>
    <div class='tuple'>
      <div class='label'>Full Name:</div>
      <div class='value'><input rv-value='state.full_name'></input></div>
    </div>
    <div class='tuple'>
      <div class='label'>E-Mail:</div>
      <div class='value'><input rv-value='state.email'></input></div>
    </div>
    <div class='tuple'>
      <div class='label'>Child Account?:</div>
      <div class='value'><input type='checkbox' rv-checked='state.minor'></input></div>
    </div>
    <div class='tuple' rv-show='state.minor'>
      <div class='label'>Parent:</div>
      <div class='value'><input type='checkbox' rv-checked='state.minor'></input></div>
    </div>
    <div>
      <button>Submit</button>
    </div>
  </div>
**/}).untab(2);

NewCustomerForm.prototype.CSS = ES5Template(function(){ /**

  .new_customer_form {
    display: inline-block;
    vertical-align: middle;
    background: rgb(60,60,60);
    padding: 1.2em;
    border-radius: 1em;
    box-shadow: 0em 0em 2em white;
  }

  .new_customer_form .form_title {
    font-size: 1.2em;
    padding: 0.5em;
  }

  .new_customer_form .tuple {
    padding: 0.5em;
    display: flex;

  }

  .new_customer_form .tuple .label {
    display: inline-block;
    width: 10em;
    flex: 0 0 8em;
  }

  .new_customer_form .tuple .value {
    display: inline-block;
    flex: 1 0 8em;
  }

**/}).untab(2);

//rivets.components['new_customer_form'] = {
//  template:   function()        { return NewCustomerForm.prototype.HTML },
//  initialize: function(el,attr) { return new NewCustomerForm(el,attr); }
//}