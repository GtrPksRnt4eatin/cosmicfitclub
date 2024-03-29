function Onboarding(el,attr) {
  
  this.dom = el;

  this.state = {
    "email"        : "",
    "id"           : "",
    "name"         : "",
    "password"     : "",
    "confirmation" : "",
    "mode"         : "login",
    "acct_found"   : false,
    "errors"       : [] 
  }

  this.load_styles();
  this.set_formatters();
  this.bind_handlers(['login','register','reset','validate_registration','check_email','email_match','clear_errors','show_http_error','submit_code']);

  $(document).keypress(function(e) { 
    if(e.keyCode != 13) return;
    if(this.state.acct_found) { this.login(); } 
    else                      { this.register(); }
  }.bind(this));

  setInterval(this.check_email,1000);
}

Onboarding.prototype = {
	constructor: Onboarding,

  set_formatters() {
    rivets.formatters.equals = function(val,testval) { return val == testval;  }
    rivets.formatters.empty  = function(val)         { return val.length == 0; }
  },

  check_email: function(e,m) { 
    let val = e && e.target ? e.target.value : $(this.dom).find(".email")[0].value;
    $.get('/auth/email_search', { email: val }, 'json' )
     .fail(    this.show_http_error )
     .success( this.email_match     )
  },

  email_match: function(val) {
    this.state.acct_found = !!val;
    if(!val) return;
    this.state.id    = val.id;
    this.state.email = val.email;
    this.state.name  = val.full_name;
  },

  login(e,m) {
    $.post('login', JSON.stringify(this.state))
     .fail(    this.show_http_error )
     .success( this.after_login     )
  },

  register() {
    if(!this.validate_registration()) return;
    var payload = JSON.stringify( { "name": this.state.name, "email": this.state.email, "password": this.state.password } )
    $.post('/auth/register_and_login', payload, 'json')
     .fail(    this.show_http_error )
     .success( this.after_login     )
  },
 
  reset() {
    $.post('reset', JSON.stringify( { "email": this.state.email } ) )
     .fail(    this.show_http_error )
     .success( function() { this.state.mode = 'email'; }.bind(this) )
  },

  validate_registration() {
    this.clear_errors();
    if(empty(this.state.name))              { this.state.errors.push("Name Cannot Be Blank");     }
    if(this.state.email.indexOf('@') == -1) { this.state.errors.push("Email Is Not Valid");       }
    if(this.state.errors.length == 0)  { return true; }
    $(this.dom).shake();
    return false;
  },

  clear_errors() {
    this.state.errors = [];
  },

  show_http_error(req,msg,status) {
    this.state.errors = [req.responseText];
    $(this.dom).shake();
  },

  after_login() {
    var page = getUrlParameter('page'); 
    window.location.replace( empty(page) ? '/user' : page );
  },

  submit_code() {
    payload = {
      token: this.state.token,
      password: this.state.password,
      confirmation: this.state.password
    }
    $.post('/auth/password', payload)
     .fail( this.show_http_error )
     .success( this.after_login )
  }

}

Object.assign( Onboarding.prototype, element);
Object.assign( Onboarding.prototype, ev_channel); 

Onboarding.prototype.HTML = `
  <div id='Onboarding' >

    <div rv-if="state.mode | equals 'login'">

      <div class='section'>Enter Your E-Mail to Register or Login</div>
      <hr>

      <div class='section'>
        <label>Email:</label>
        <input class='email' rv-value='state.email' rv-on-input='check_email'></input>
      </div>

      <div class='section'>
        <label>Password:</label>
        <input class='password' type='password' rv-value='state.password'></input>
      </div>

      <div class='section' rv-hide='state.acct_found'>
        <label>Full Name:</label>
        <input rv-value='state.name'></input>
      </div>

      <div class='section'>
        <div rv-if='state.acct_found' class='submit' rv-on-click='login'>Login</div>
        <div rv-unless='state.acct_found' class='submit' rv-on-click='register'>Register</div>
      </div>

      <div class='fineprint' rv-if='state.acct_found'>
        <hr>
        Forgot Password?
        <span rv-on-click='reset'>Reset Password</span>
      </div>

      <div rv-unless='state.errors | empty'>
        <hr>
        <div class='error' rv-each-err='state.errors'> {err} </div>
      </div>
      
    </div>

    <div rv-if="state.mode | equals 'email'">
      <span class='backbtn' rv-on-click="this.login_mode"></span>
      <div class="section">Check Your Email</div>
      <hr>
      <div class="section">
        <div>Check your E-Mail for a message from Donut!</div>
        <img class='donut' src='donut_desk.png'/>
        <div class='section'>
          <label>Reset Token:</label><input id='token' rv-value='state.token'></input>
        </div>
        <div class='section'>
          <label>New Password:</label><input type='password' rv-value='state.password'></input>
        </div>
        <button rv-on-click='submit_code'>Reset Password</button>
      </div>
    </div>

  </div>
`.untab(2);

Onboarding.prototype.CSS = `

  #Onboarding {
    position: relative;
    display: inline-block;
    text-align: center;
    background: rgba(255,255,255,0.2);
    padding: 20px;
    border: 1px solid black;
    box-shadow: 0 0 4px rgba(0,0,0,0.5), 0 0 4px rgba(0,0,0,0.5) inset;
    padding: 1em;
  }

  #Onboarding .backbtn {
    cursor: pointer;
    display: inline-block;
    position: absolute;
    top: 1.4em;
    left: 1.4em;
    width: 0;
    height: 0;
    border-top: 10px solid transparent;
    border-bottom: 10px solid transparent;
    border-right: 10px solid blue;
  }

  #Onboarding .section {
    padding: .5em;
  }

  #Onboarding label {
  	line-height: 1.5em;
  }

  #Onboarding input {
  	float: right;
    margin-left: 1em;
  }

  #Onboarding .submit {
  	display: block;
  	cursor: pointer;
    margin-top: .3em;
    padding: .5em 2em;
    box-shadow: 0 0 .1em white;
    background: rgba(255,255,255,0.1);
  }

  #Onboarding .submit:hover {
    cursor: pointer;
    color: rgba(150,255,150,1);
    background: rgba(255,255,255,0.2);
    text-shadow: 0 0 .5em black;
  }

  #Onboarding .fineprint {
    padding: 0.5em;
    font-size: 0.7em;
  }

  #Onboarding .fineprint span {
    cursor: pointer;
    color: rgba(150,255,150,1);
    text-shadow: 0 0 .5em black;
    text-align: right;
    display: inline-block;
    padding: 0 1em;
    width: 10em;
  }

  #Onboarding .error {
    color: rgba(255,150,150,1);
    text-shadow: 0 0 .5em black;
    font-size: 0.7em;
  }

  #Onboarding .omni img {
    width: 60%;
  }

  #Onboarding img.donut {
    margin-top: 1em;
  }

`.untab(2);

rivets.components['onboarding'] = {
  template:   function()        { return Onboarding.prototype.HTML },
  initialize: function(el,attr) { return new Onboarding(el,attr); }
}