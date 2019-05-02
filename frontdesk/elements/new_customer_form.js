function NewCustomerForm(el, attr, build_dom) {

  this.dom  = el || render(this.HTML);;
  this.attr = attr;

  this.load_styles();
  this.bind_handlers([]);
  this.build_dom(parent);
  this.bind_dom();

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

**/}).untab(2);

//rivets.components['new_customer_form'] = {
//  template:   function()        { return NewCustomerForm.prototype.HTML },
//  initialize: function(el,attr) { return new NewCustomerForm(el,attr); }
//}