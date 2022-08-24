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
      let price = sess.custom && sess.custom.slot_pricing ? sess.custom.slot_pricing[v.length - 1] : sess.individual_price_full * v.length;
      return { 
        session_id: v[0]['session_id'], 
        count: v.length, 
        price: price,
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
  this.load_styles();
}

SessionList.prototype = {
	constructor: SessionList,

  checkout: function(e,m) {
    let payload = { 
      price: this.price_cents(),
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
    <br/>
    <button rv-on-click='checkout'>
      Pay { passes | total_price } Now
    </button>
  </div>
**/}).untab(2);

SessionList.prototype.CSS = `
  .session_list {
    margin: 1em 0;
    padding: 1em;
    border: 1px solid white;
  }  


`.untab(2);

rivets.components['session-list'] = { 
  template:   function()        { return SessionList.prototype.HTML; },
  initialize: function(el,attr) { return new SessionList(el,attr);   }
}