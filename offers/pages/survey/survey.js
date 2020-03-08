var checkout;

var email_regex = /(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])/
emails = ["bklein261@gmail.com","Aak418@gmail.com","addnab@gmail.com","adricristina89@hotmail.com","agnew_char@hotmail.com","alan423956@yahoo.com","Amayzlin@yahoo.com","amy.furman06@gmail.com","amy.winn@gmail.com","Andy205k@aol.com","angche00@gmail.com ","anna.nassiff@gmail.com","aoifeduna@gmail.com","ariana96iko@gmail.com","asbalon@yahoo.com","asbalon@yahoo.com","Baruch.tabanpour@gmail.com ","bill.donohue@comcast.net","briankeithkeil@gmail.com","Cct7797@gmail.com","Celjoh76@yahoo.com","christine.stoica@gmail.com","cknightharper@gmail.com","cl10@alumni.princeton.edu","Cynthia.silva212@gmail.com ","Damien.archbold@gmail.com","Danielamacazaga@gmail.com ","danieldozark@gmail.com","Davidrubinstein93@gmail.com","dchaws@gmail.com","Dquaythevenon@gmail.com","Ebyaffe@outlook.com","eliasrepka@gmail.com","elzarad@gmail.com","Emery.mikel@gmail.com","emilee928@gmail.com","Findbeatrice@gmail.com","Francestroche@gmail.com","frank.wuu@gmail.com","Gliiterbluerain@gmail.com","gospex@gmail.com","Hackett.Christine@gmail.com","Hmettinger@yahoo.com","Holycowantonio@gmail.com","hypolite.kathy@gmail.com","info@freeda.com","javzlala@hotmail.com","jennifermargulis@gmail.com","johnthedebs@gmail.com","Josephzengotita@gmail.com","josettepenzel@gmail.com","jpgamez1789@icloud.com","julia.torrant@yahoo.com","Kikonyx@gmail.com","klein2477@gmail.com","lahexp@aol.com","lockerastrid@gmail.com","markalasstavros@gmail.com","mc72007@yahoo.com","meinders@ualberta.ca","Melissabieri@yahoo.com","mhg0903@nyc.rr.com ","mikeresh@gmail.com","multiantoniob@gmail.com","Nchausow@gmail.com","Noel.Barrott@gmail.com","Opuntus@yahoo.com","Parker.shippey@gmail.com","Pfernandez@vassar.edu","raegl6@gmail.com ","Rbmartin_1999@yahoo.com","Rebeccafenton73@gmail.com","Romebram@yahoo.com","Ryan.r.miller92@gmail.com","sarahacasper@gmail.com","seskusam@aol.com","Sushifatty@gmail.com","Thetrucstop@gmail.com","tiacsia@gmail.com","Valbona.berisha@gmail.com","Valbona.berisha@gmail.com","Valbona.berisha@gmail.com","veronicapaquilla@gmail.com","xavierxv18@gmail.com","y00.me.art@gmail.com","yogabysinda@gmail.com",]

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
    if( userview.logged_in) { checkout( userview.id ); return; }
    if( !data.id )          { if( !validate_noid()  ) { return; }; create_account(); }
    if( data.id  )          { login(); }
  },

  reset_password: function(e,m) {
    $.post( '/auth/reset', JSON.stringify( { "email" : data.email } ) )
     .fail(    function(req,msg,status) { ('#offer_form').shake(); data.errors=["Account Not Found!"] } )
     .success( function() { alert("Check Your Email"); } )
  }

}

$(document).ready(function(){

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

    $(document).keypress(function(e) { 
      if(e.keyCode != 13) { return true; }
      ctrl.checkout();
    });

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
  $.post('/auth/register_and_login', JSON.stringify( { "name": data.full_name, "email": data.email } ), 'json')
   .fail( function(req,msg,status) { $('#offer_form').shake(); data.errors = ['failed to create account']; } )
   .success( function() { userview.get_user( function(user) { checkout(user.id); } ); } );
}

function login() {
  $.post('/auth/login', JSON.stringify({ "email" : data.email, "password" : data.password } ))
  .fail( function(req,msg,status) { $('#offer_form').shake(); data.errors=["Login Failed"] } )
  .success( function() { userview.get_user( function(user) { checkout(user.id); } ); } );
}

function validate_noid() {
  data.errors = [];
  if( !email_regex.test( id('email').value ) ) { data.errors.push("Invalid E-Mail Address!"); $('#offer_form').shake(); return false; }
  if( id('fullname').value.length == 0 )       { data.errors.push("Name Cannot Be Empty");    $('#offer_form').shake(); return false; }
  return true;
}

function checkout(customer_id) {
  if(!emails.includes(userview.user.email)) { alert("You Must Have Completed the Survey to be Eligible."); return; }
  payment_form.checkout( customer_id, 17000, "Ten Pack ($10 off survey reward)", null, function(payment_id) {
      $.post('/checkout/pack/buy', { customer_id: customer_id, pack_id: 10, payment_id: payment_id })
       .success( function() { alert("Purchase Successful!"); window.location.href = '/user'; } );
    });
}