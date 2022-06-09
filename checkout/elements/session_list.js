function SessionList(parent,attr) {
  this.passes = attr['passes'];

  rivets.formatters.session_passes = function(passes) {
      passes.groupBy(function(p) { return p['session_id']; })
  }
}

SessionList.prototype = {
	constructor: SessionList,
}


Object.assign( SessionList.prototype, element);
Object.assign( SessionList.prototype, ev_channel);

SessionList.prototype.HTML = ES5Template(function(){/**
  <div class='session_list'>
    <div rv-each-sess='passes | session_passes'>
      <span> { sess.customer_string } </span>
    </div>
  </div>
**/}).untab(2);

SessionList.prototype.CSS = `
  
`.untab(2);

rivets.components['session-list'] = { 
  template:   function()        { return SessionList.prototype.HTML; },
  initialize: function(el,attr) { return new SessionList(el,attr);   }
}