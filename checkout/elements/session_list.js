function SessionList(parent,attr) {
  this.passes = attr['passes'];

  rivets.formatters.session_passes = function(passes) {
    let result = passes.reduce(function(result,obj) {
        result[obj['session_id']] = result[obj['session_id']] || [];
        result[obj['session_id']].push(obj); 
        return result;
    },{});
    return Object.values(result).map( function(v) { return { session_id: x[0]['session_id'], passes: v } } )
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
      <span> hello </span>
    </div>
  </div>
**/}).untab(2);

SessionList.prototype.CSS = `
  
`.untab(2);

rivets.components['session-list'] = { 
  template:   function()        { return SessionList.prototype.HTML; },
  initialize: function(el,attr) { return new SessionList(el,attr);   }
}