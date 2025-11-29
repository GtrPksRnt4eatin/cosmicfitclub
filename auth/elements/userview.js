function UserView(parent) {
	
  this.state = {
	  "user": null
  }

  this.build_dom(parent);
  this.load_styles();
  this.bind_dom();
  this.get_user();
  
}

UserView.prototype = {
	constructor: UserView,

  login()    { document.cookie = "loc=" + window.location.pathname; window.location = '/auth/login'; },
  onboard()  { document.cookie = "loc=" + window.location.pathname; window.location = '/auth/onboard?page=' + window.location.pathname; },
  logout()   { $.post('/auth/logout', function() { window.location.reload(); } ); },
  userpage() { window.location = '/user'; },

  get_user(callback) {
    $.get('/auth/current_user')
      .fail( function()     { this.state.user = null; this.ev_fire('on_user', null); }.bind(this))
      .done( function(user) { 
        this.state.user = user; 
        this.ev_fire('on_user', user); 
        if(callback) { callback.call(null,user); }
      }.bind(this));
  },

  get id() {
    return ( this.state.user ? this.state.user.id : 0 );
  },

  get custy_string() {
    return  ( this.state.user ? `${this.state.user.name} ( ${this.state.user.email} )` : "" );
  },

  get user() {
    return this.state.user;
  },

  get logged_in() {
    return !!this.state.user;
  }

}

Object.assign( UserView.prototype, element);
Object.assign( UserView.prototype, ev_channel);

UserView.prototype.HTML = ES5Template(function(){/**

  <div id="UserView">
    <div rv-if='state.user'>
      <div class='name'><a href='/user'>{state.user.name}</a></div> |
      <div class='logout' rv-on-click='this.logout'>Logout</div>
    </div>
    <div rv-unless='state.user'>
      <div class='login' rv-on-click='this.login'>LOG IN</div>
    </div>
  </div>

**/}).untab(2);

UserView.prototype.CSS = ES5Template(function(){/**
  
  #UserView > div {
    display: flex;
  }

  #UserView img {
    height: 1.5em;
    width: 1.5em;
    vertical-align: middle;
    border: 1px solid black;
    display: none;
  }

  #UserView .name {
    line-height: 1.6em;
    display: inline-block;
    padding: 0 .5em;
    cursor: pointer;
  }

  #UserView .logout {
    line-height: 1.6em;
    display: inline-block;
    padding: 0 .5em;
    cursor: pointer;
  }

  #UserView .login {
    line-height: 1.6em;
    display: inline-block;
    padding: 0 .5em;
    cursor: pointer;
  }

  #UserView .login:hover,
  #UserView .logout:hover,
  #UserView .name:hover {
    text-shadow: 0 0 0.5em rgb(100,100,255), 0 0 0.5em rgb(100,100,255);
  }

  #UserView .login {
    padding: .5em 1em !important;
    font-weight: bold;
    line-height: 1em !important;
  }

**/}).untab(2);
