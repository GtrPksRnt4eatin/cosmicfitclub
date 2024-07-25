function SessionList(parent,attr) {
  this.event     = attr['event'];
  this.passes    = attr['passes'];
  this.discounts = []; 

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
      let addons = sess.custom && sess.custom.addons ? sess.custom.addons.filter(function(x) { return x.checked; }) : [];
      let addons_price = addons.reduce(function(sum,x) { return(sum + x.price); }, 0 );
      return { 
        session_id: v[0]['session_id'], 
        count: v.length, 
        price: price,
        session: sess,
        passes: v,
        addons: addons,
        addons_price: addons_price
      }
    }.bind(this) )
  }.bind(this);

  rivets.formatters.total_price = function(passes) {
    this.apply_discounts();
    passes = rivets.formatters.session_passes(passes);
    result = passes.reduce(function(result,obj) {
      return result + obj['price'] + obj['addons_price'];
    },0);
    this.discounts.forEach( function(d) { result = result + d.amount } );
    return rivets.formatters.money(result);
  }.bind(this);


  this.bind_handlers(['checkout', 'price_cents', 'apply_discounts']);
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
    let price = passes.reduce(function(result,obj) {
      return result + obj['price'] + obj['addons_price'];
    },0);
    this.discounts.forEach( function(d) { price = price + d.amount } );
    return price;
  },

  apply_discounts: function() {
    this.discounts = [];
    let sess1 = this.passes.filter(function(x) { return x.session_id==1191 } ).length;
    let sess2 = this.passes.filter(function(x) { return x.session_id==1192 } ).length;
    let sess3 = this.passes.filter(function(x) { return x.session_id==1193 } ).length;
    
    let triple_count = Math.min(sess1,sess2,sess3);
    triple_count && this.discounts.push({ name: "$15 Triple Workshop Discount", count: triple_count, amount: triple_count * -1000 })
    sess1 -= triple_count;
    sess2 -= triple_count;
    sess3 -= triple_count;
    
    let double_count = Math.max(Math.min(sess1,sess2),Math.min(sess2,sess3),Math.min(sess1,sess3));
    double_count && this.discounts.push({ name: "$10 Double Workshop Discount", count: double_count, amount: double_count * -2000 })

    ////////////// bannequine barnaby //////////////////
    //sess1 = this.passes.filter(function(x) { return x.session_id==907 } ).length;
    //sess2 = this.passes.filter(function(x) { return x.session_id==912 } ).length;
    //double_count = Math.min(sess1,sess2);
    //double_count && this.discounts.push({ name: "$20 Double Workshop Discount", count: double_count, amount: double_count * -2000 })
  }

}

Object.assign( SessionList.prototype, element);
Object.assign( SessionList.prototype, ev_channel);

SessionList.prototype.HTML = ES5Template(function(){/**
  <div class='session_list' rv-show='passes'>
    <table>
      <tbody rv-each-sess='passes | session_passes'>
        <tr>
          <td> { sess.session.start_time | eventstart } </td>
          <td> { sess.session.title } </td>
          <td> x{ sess.count } </td>
          <td> { sess.price | money } </td>
        </tr>
        <tr rv-each-addon='sess.addons'>
          <td></td>
          <td> { addon.name} </td>
          <td></td>
          <td> { addon.price | money }</td>
        </tr>
      </tbody>
      <tr rv-each-disc='discounts'>
        <td colspan='2'>{ disc.name }</td>
        <td> x{ disc.count }</td>
        <td>{ disc.amount | money }</td>
      </tr>
      <tr>
        <td colspan='2'> <b> TOTAL</b> </td>
        <td></td>
        <td> { passes | total_price } </td>
    </table>
    <button class='checkout' rv-on-click='checkout'>
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

  .session_list table {
    width: 100%;
    box-sizing: border-box
  }

  .session_list td:last-child {
    width:5em;
  }

  .session_list .checkout {
    font-size: 1.2em;
    width: 100%;
    padding: 0.2em;
    cursor: pointer;
    margin-top: 0.2em;
    box-sizing: border-box;
  }
`.untab(2);

rivets.components['session-list'] = { 
  template:   function()        { return SessionList.prototype.HTML; },
  initialize: function(el,attr) { return new SessionList(el,attr);   }
}
