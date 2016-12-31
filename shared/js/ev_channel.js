ev_channel = {

  ev_fire(eventname, payload) {
    this.ev_listeners = this.ev_listeners || [];
    var listeners = this.ev_listeners.filter( function(listener) { return listener.event == eventname; } );
    listeners.forEach( function(listener) { listener.callback.call(this,payload); } );
  },	
  
  ev_sub(eventname,callback) {
    this.ev_listeners = this.ev_listeners || [];
  	var token = this.ev_gen_token();
    var listener = { token: token, event: eventname, callback: callback }
    this.ev_listeners.push(listener);
    return token;
  },

  ev_unsub(token) {
    this.ev_listeners = this.ev_listeners.filter( function(listener) { return listener.token != token; } );
  },

  ev_gen_token() { return Math.random().toString(36).slice(2); }

}