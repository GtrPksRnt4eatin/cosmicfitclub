function LoginForm(parent) {
  
  this.state = {
    "email": "",
    "password": "",
    "mode": "",
  }

  this.build_dom(parent);
  this.load_styles();
  this.bind_dom();
}

LoginForm.prototype = {
	constructor: LoginForm,

}

Object.assign( LoginForm.prototype, element);
Object.assign( LoginForm.prototype, ev_channel);

LoginForm.prototype.HTML = `
  <div id='LoginForm'>
    <div class='section'>Login To Continue</div>
    <div class='section' style='display: none;'>
      <label>Email:</label>
      <input class='username'></input>
    </div>
    <div class='section' style='display: none;'>
      <label>Password:</label>
      <input class='password' type='password'></input>
    </div>
    <div class='section' style='display: none;'>
      <div class='submit'>Login</div>
    </div>
    <hr>
    <div class='section'>
      <a href='omni/facebook'>
        <img src='login-facebook.png'/>
      </a>
    </div>
    <div class='section' style='display: none;'>
      <a href='omni/google_oauth2'>
        <img src='login-google.png'/>
      </a>
    </div>
  </div>
`.untab(2);

LoginForm.prototype.CSS = `

  #LoginForm {
    display: inline-block;
    text-align: center;
    padding: 20px;
    border: 1px solid black;
    padding: 1em;
  }

  #LoginForm .section {
    padding: .5em;
    width: 19em;
    min-height: 1.5em;
  }

  #LoginForm label {
  	line-height: 1.5em;
    float: left;
  }

  #LoginForm input {
  	float: right;
    font-size: 1em;
  }

  #LoginForm .submit {
  	display: inline-block;
  	cursor: pointer;
  	margin: auto;
  	right: 0;	
    background: rgba(0,0,0,0.6);
    color: white;
    width: 100%;
    line-height: 2.5em;
    height: 2.5em;
  }

  #LoginForm img {
    width: 100%;
    cursor: pointer;
  }

`.untab(2);