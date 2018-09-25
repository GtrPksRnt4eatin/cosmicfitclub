var checkout;

var email_regex = /(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])/

data = {
  id: 0,
  email: null,
  full_name: null,
  password: null,
  errors: [],
  logged_in: false
}

ctrl = {
  
  check_email: function(e,m) { 
    $.get('/auth/email_search', { email: e.target.value }, function(val) {
      data.errors = [];
      data.id = val ? val.id : 0;
      data.email = val ? val.email : data.email;
      data.full_name = val ? val.full_name : '';
      id('fullname').disabled = val ? true : false;
    } );
  },

  checkout: function(e,m) {
    if( userview.logged_in) { payment_form.checkout( data.id, 10000, "Ten Class Pack (discounted)", null, on_payment); return; }
    if( !data.id )          { if( !validate_noid()  ) { return; }; create_account(); }
    if( data.id  )          { login(); }
    checkout( data.id );
  },

  reset_password: function(e,m) {
    $.post( '/auth/reset', JSON.stringify( { "email" : data.email } ) )
     .fail(    function(req,msg,status) { ('#offer_form').shake(); data.errors=["Account Not Found!"] } )
     .success( function() { alert("Check Your Email"); } )
  }

}

$(document).ready(function(){

	//include_rivets_dates();
    include_rivets_money();

    payment_form     = new PaymentForm();
    popupmenu        = new PopupMenu( id('popupmenu_container') );
    userview         = new UserView( id('userview_container') );

    payment_form.customer_facing();
    payment_form.clear_customer();
    payment_form.ev_sub('show', popupmenu.show );
    payment_form.ev_sub('hide', popupmenu.hide );
    popupmenu.ev_sub('close', payment_form.stop_listen_cardswipe);

    userview.ev_sub('on_user', on_user );

    rivets.formatters.not_if_loggedin = function(val) { if(userview.logged_in) return false; return val; }
    var binding = rivets.bind( $('body'), { ctrl: ctrl, data: data } );

})

function on_user(user) {
  if( empty(user) ) { payment_form.clear_customer();      }
  else              { payment_form.get_customer(user.id); }
  data.logged_in = empty(user) ? false : true;
  data.id = empty(user) ? 0 : user.id;
  data.full_name = empty(user) ? '' : user.name;
  data.email = empty(user) ? '' : user.email;
  id('email').disabled = empty(user) ? false : true;
  id('fullname').disabled = empty(user) ? false : true;
}

function create_account() {
  $.post('/auth/register_and_login', JSON.stringify({
      "name": data.full_name,
      "email": data.email
    }), 'json')
   .fail( function(req,msg,status) { data.errors = ['failed to create account'];  $('#offer_form').shake(); } )
   .success( function(resp) {
      userview.get_user();
      checkout(resp.id)
    });
}

function login() {
  $.post('/auth/login', JSON.stringify({ "email" : data.email, "password" : data.password } ))
  .fail( function(req,msg,status) { ('#offer_form').shake(); data.errors=["Login Failed"] } )
  .success( function() { 
    userview.get_user();
    checkout(data.id);
  });
}

function validate_noid() {
  data.errors = [];
  if( !email_regex.test( id('email').value ) ) { data.errors.push("Invalid E-Mail Address!"); $('#offer_form').shake(); return false; }
  if( id('fullname').value.length == 0 )       { data.errors.push("Name Cannot Be Empty");    $('#offer_form').shake(); return false;}
  return true;
}

function login() {
  $.post('login', JSON.stringify(this.state))
   .fail( function(req,msg,status) { $(this.dom).shake();  this.state.failed=true; }.bind(this) )
   .success( function() { 
     var page = getUrlParameter('page');
     window.location.replace( empty(page) ? '/user' : page );
   });
}

function checkout(customer_id) {
  payment_form.checkout( customer_id, 10000, "Ten Class Pack (discounted)", null, function(payment_id) {
      $.post('/checkout/pack/buy', { customer_id: customer_id, pack_id: 4, payment_id: payment_id })
       .success( function() { alert("Purchase Successful!"); window.location.href = '/user'; } );
    });
}

function on_payment(payment) {
  var x=5;
}