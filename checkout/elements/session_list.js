function SessionList(parent,attr) {
  this.event  = attr['event'];
  this.passes = attr['passes'];

  rivets.formatters.session_passes = function(passes) {
    let result = passes.reduce(function(result,obj) {
        result[obj['session_id']] = result[obj['session_id']] || [];
        result[obj['session_id']].push(obj); 
        return result;
    },{});
    if(!this.event) return([]);
    return Object.values(result).map( function(v) { 
      let sess = this.event.sessions.find( function(s) { return s.id == v[0]['session_id'] } );
      return { 
        session_id: v[0]['session_id'], 
        count: v.length, 
        price: sess.custom.slot_pricing[v.length - 1],
        session: sess,
        passes: v 
      }
    }.bind(this) )
  }.bind(this);

  rivets.formatters.total_price = function(passes) {
    passes = rivets.formatters.session_passes(passes);
    result = passes.reduce(function(result,obj) {
      return result + obj['price'];
    },0);
    return rivets.formatters.money(result);
  }.bind(this);


  this.bind_handlers(['checkout', 'price_cents']);
}

SessionList.prototype = {
	constructor: SessionList,

  checkout: function(e,m) {
    let payload = { 
      price: this.price_cents,
      passes: this.passes 
    }
    this.ev_fire('checkout', payload);
  },

  price_cents: function() {
    let passes = rivets.formatters.session_passes(this.passes);
    return passes.reduce(function(result,obj) {
      return result + obj['price'];
    },0);
  }

}

Object.assign( SessionList.prototype, element);
Object.assign( SessionList.prototype, ev_channel);

SessionList.prototype.HTML = ES5Template(function(){/**
  <div class='session_list' rv-show='passes'>
    <table>
      <tr rv-each-sess='passes | session_passes'>
        <td> { sess.session.start_time | eventstart } </td>
        <td> { sess.session.title } </td>
        <td> x{ sess.count } </td>
        <td> { sess.price | money } </td>
      </tr>
      <tr>
        <td colspan='2'> <b> TOTAL</b> </td>
        <td></td>
        <td> { passes | total_price } </td>
        <td class='edit'></td>
        <td class='cancel'></td>
    </table>
    <button rv-on-click='checkout'>
      Pay { passes | total_price } Now
    </button>
  </div>
**/}).untab(2);

SessionList.prototype.CSS = `
  .session_list {
    margin: 1em 0;
    border: 1px solid white;
  }  


`.untab(2);

rivets.components['session-list'] = { 
  template:   function()        { return SessionList.prototype.HTML; },
  initialize: function(el,attr) { return new SessionList(el,attr);   }
}