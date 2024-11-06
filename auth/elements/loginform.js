function LoginForm(parent) {
  
  this.state = {
    "name"         : "",
    "email"        : "",
    "password"     : "",
    "confirmation" : "",
    "mode"         : "login",
    "failed"       : false,
    "no_exp"       : false,
    "errors"       : [] 
  }

  this.set_formatters();
  this.bind_handlers(['login','register','reset','login_mode','register_mode','reset_mode', 'email_mode']);
  this.build_dom(parent);
  this.load_styles();
  this.bind_dom();

  $(document).keypress(function(e) { 
    if(e.keyCode != 13) { return true; }
    switch(this.state.mode) {
      case "login":    this.login();    break;
      case "register": this.register(); break;
      case "reset":    this.reset();    break;
    }
  }.bind(this));

}

LoginForm.prototype = {
	constructor: LoginForm,

  set_formatters() {
    rivets.formatters.equals = function(val,testval) { return val == testval;  }
    rivets.formatters.empty  = function(val)         { return val.length == 0; }
  },

  login() {
    $.post('login', JSON.stringify(this.state))
      .fail( function(req,msg,status) { $(this.dom).shake();  this.state.failed=true; }.bind(this) )
      .success( function() { 
        var page = getUrlParameter('page');
        window.location.replace( empty(page) ? '/user' : page );
      });
  },

  register() {
    if(this.validate_registration()) {
      $.post('register_and_login', JSON.stringify(this.state))
        .fail( function(req,msg,status) { 
          $(this.dom).shake(); 
          this.state.errors=[req.responseText];
        }.bind(this) )
        .success( 
          function() { window.location.replace('/user'); }
        );
    }
  },

  reset() {
    $.post('reset', JSON.stringify(this.state))
      .fail( function(req,msg,status) {
        $(this.dom).shake();
        this.state.errors=["Account Not Found!"]
      }.bind(this) )
      .success( this.email_mode );
  },

  login_mode()    { this.state.mode = "login";    },
  register_mode() { this.state.mode = "register"; },
  reset_mode()    { this.state.mode = "reset";    },
  email_mode()    { this.state.mode = "email";    },

  validate_registration() {
    this.state.errors = [];
    if(empty(this.state.name))              { this.state.errors.push("Name Cannot Be Blank");     }
    if(this.state.email.indexOf('@') == -1) { this.state.errors.push("Email Is Not Valid");       }
    if(this.state.errors.length == 0)  { return true; }
    $(this.dom).shake();
    return false;
  }

}

Object.assign( LoginForm.prototype, element);
Object.assign( LoginForm.prototype, ev_channel); 

LoginForm.prototype.HTML = `
  <div id='LoginForm' >

    <div rv-if="state.mode | equals 'login'">
      <div class='section'>Login To Continue</div>
      <hr>
      <div class='section'>
        <label>Email:</label>
        <input class='email' rv-value='state.email'></input>
      </div>
      <div class='section'>
        <label>Password:</label>
        <input class='password' type='password' rv-value='state.password'></input>
      </div>
      <hr style='display: none;' >
      <div class='section'>
        <div class='submit' rv-on-click='this.login'>Login</div>
      </div>
      <hr style='display: none;' >
      <div class='section' style='display: none;' >
        <a class='omni' href='omni/facebook'>
          <img src='login-facebook.png'/>
        </a>
      </div>
      <div class='section' style='display: none;'>
        <a class='omni' href='omni/google_oauth2'>
          <img src='login-google.png'/>
        </a>
      </div>
      <hr>
      <div class='fineprint'>Leave Me Signed In: <input type='checkbox' rv-checked='state.no_exp'/></div>
      <div class='fineprint'>Not Registered?<span rv-on-click='this.register_mode'>Create An Account</span></div>
      <div class='fineprint' rv-if="state.failed">
        Forgot Password?
        <span rv-on-click='this.reset_mode'>Reset Password</span>
      </div>
    </div>

    <div rv-if="state.mode | equals 'register'">
      <span class='backbtn' rv-on-click="this.login_mode"></span>
      <div class='section'>Enter Your Information</div>
      <hr>
      <div class='section'>
        <label>Name:</label>
        <input rv-value='state.name'></input>
      </div>
      <div class='section'>
        <label>E-Mail:</label>
        <input rv-value='state.email'></input>
      </div>
      <hr>
      <div class='section'>
        <div class='submit' rv-on-click='this.register'>Register</div>
      </div>
      <div rv-unless='this.state.errors | empty'>
        <hr>
        <div class='error' rv-each-err='this.state.errors'> {err} </div>
      </div>
    </div>

    <div rv-if="state.mode | equals 'reset'">
      <span class='backbtn' rv-on-click="this.login_mode"></span>
      <div class='section'>Reset Your Password</div>
      <hr>
      <div class='section'>
        <label>E-Mail:</label>
        <input rv-value='state.email'></input>
      </div>
      <hr>
      <div class='section'>
        <div class='submit' rv-on-click='this.reset'>Reset</div>
      </div>
      <div rv-unless='this.state.errors | empty'>
        <hr>
        <div class='error' rv-each-err='this.state.errors'> {err} </div>
      </div>
    </div>

    <div rv-if="state.mode | equals 'email'">
      <span class='backbtn' rv-on-click="this.login_mode"></span>
      <div class="section">Check Your Email</div>
      <hr>
      <div class="section">
        <div>Check your E-Mail for a message from Donut!</div>
        <img class='donut' src='donut_desk.png'/>
      </div>
    </div>

  </div>
`.untab(2);

LoginForm.prototype.CSS = `

  #LoginForm {
    position: relative;
    display: inline-block;
    text-align: center;
    background: rgba(255,255,255,0.2);
    padding: 20px;
    border: 1px solid black;
    box-shadow: 0 0 4px rgba(0,0,0,0.5), 0 0 4px rgba(0,0,0,0.5) inset;
    padding: 1em;
  }

  #LoginForm .backbtn {
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

  #LoginForm .section {
    padding: .5em;
  }

  #LoginForm label {
  	line-height: 1.5em;
  }

  #LoginForm input {
  	float: right;
    margin-left: 1em;
  }

  #LoginForm .submit {
  	display: block;
  	cursor: pointer;
    margin-top: .3em;
    padding: .5em 2em;
    box-shadow: 0 0 .1em white;
    background: rgba(255,255,255,0.1);
  }

  #LoginForm .submit:hover {
    cursor: pointer;
    color: rgba(150,255,150,1);
    background: rgba(255,255,255,0.2);
    text-shadow: 0 0 .5em black;
  }

  #LoginForm .fineprint {
    padding: 0.5em;
    font-size: 0.7em;
  }

  #LoginForm .fineprint span {
    cursor: pointer;
    color: rgba(150,255,150,1);
    text-shadow: 0 0 .5em black;
    text-align: right;
    display: inline-block;
    padding: 0 1em;
    width: 10em;
  }

  #LoginForm .error {
    color: rgba(255,150,150,1);
    text-shadow: 0 0 .5em black;
    font-size: 0.7em;
  }

  #LoginForm .omni img {
    width: 60%;
  }

  #LoginForm img.donut {
    margin-top: 1em;
  }

`.untab(2);