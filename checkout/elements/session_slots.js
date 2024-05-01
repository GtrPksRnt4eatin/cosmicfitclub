function SessionSlots(parent,attr) {

  this.event           = attr['event'];
  this.session         = attr['session'];
  this.customer        = attr['customer'];
  this.choose_customer = attr['choose_customer'];
  this.session_passes  = attr['passes'];

  this.state = {
    num_slots: 1,
    passes: [],
    slot_options: []
  }
	
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
    passes = rivets.formatters.session_passes(passes);
    result = passes.reduce(function(result,obj) {
      return result + obj['price'] + obj['addons_price'];
    },0);
    return rivets.formatters.money(result);
  }.bind(this);

  this.bind_handlers(['set_num_slots', 'num_slots_selected', 'set_slot_options', 'check_for_existing', 'set_first_slot','clear_session', 'choose_custy','add_to_order']);
  this.load_styles();

}

SessionSlots.prototype = {
  constructor: SessionSlots,

  set_num_slots(n) {
    this.state.num_slots = n;
    while(this.state.passes.length<this.state.num_slots) {
      this.state.passes.push({ session_id: this.session.id, customer_id: 0, customer_string: 'Add Student' }); 
    }
    while(this.state.passes.length>this.state.num_slots){
      this.state.passes.pop();
    }
  },

  num_slots_selected(e,m) {
    let n = parseInt(e.target.value);
    this.set_num_slots(isNaN(n) ? 1 : n);
  },

  set_slot_options() {
    if(this.session.custom && this.session.custom.slot_pricing) {
      this.state.slot_options = this.session.custom.slot_pricing.reduce( function(arr,el,idx) { 
        if(el) arr.push(idx+1); 
        return arr;
      }, []);
    }
    else {
      this.state.slot_options = [ ...Array(this.session.available_slots + 1).keys()]
      this.state.slot_options.shift();
    }
  },

  check_for_existing() {
    this.set_slot_options();
    this.set_num_slots(0);
    let matches = this.session_passes.filter(function(val) { return val['session_id'] == this.session.id; }.bind(this));
    if(matches.length==0) {
      this.set_first_slot({ list_string: this.customer.name + ' ( ' + this.customer.email + ' )' , ...this.customer}); 
    }
    else {
      matches.forEach(function(val) {
        let idx = this.session_passes.indexOf(val);
        if(idx > -1) {
          this.state.passes.push(val);
          this.session_passes.splice(idx,1);
        }
      }.bind(this));
      this.state.num_slots = matches.length;
    }  
  },

  set_first_slot(customer) {
    this.state.passes.push({ session_id: this.session.id, customer_id: customer.id, customer_string: customer.list_string });
    this.set_num_slots(this.state.slot_options[0]);
  },

  clear_session() { 
    this.session = null; 
    this.ev_fire('passes_updated', this.state.slots);
  },

  choose_custy(e,m) {
    this.choose_customer(m.slot.customer_id, function(val) { 
      Object.assign(this.state.passes[ m['%slot%'] ],{ session_id: this.session.id, ...val }); 
    }.bind(this) );
  },

  add_to_order() {
    this.session = null;
    this.session_passes.push(...this.state.passes);
    this.ev_fire('passes_updated', this.state.slots);
  }
}

Object.assign( SessionSlots.prototype, element);
Object.assign( SessionSlots.prototype, ev_channel);

SessionSlots.prototype.HTML = `
  <div id='private_slots' rv-show='session' >
    <hr class='mobile'><br class='mobile'>   

    <div class='selected_timeslot'>
      <h2>{ session.title }</h2>
      <h3>{ session.start_time | fulldate } - {session.end_time | time }</h3>
      <span style="cursor:pointer; color: #9999FF;" rv-on-click="clear_session">cancel/remove session</span>
      <br/><br/>

      <div class='tuple'>
        <div class='attrib'># People</div>
        <div class='value'>
          <select class='num_students' rv-value='state.num_slots' rv-on-change='num_slots_selected'>
            <option rv-each-val='state.slot_options' rv-value="val">{val}</option>
          </select>  
        </div>
      </div> 

      <div rv-show='state.num_slots'>
        <hr/>
        <div class='tuple slots' rv-each-slot='state.passes'>
          <div class='attrib'>Slot #{index | fix_index}</div>
          <div class='value' rv-on-click='choose_custy'>
            {slot.customer_string}           
          </div>
        </div>
      </div>
      
      <div rv-show='session.custom.addons'>
        <hr/>
        <div class='tuple'>
          <div class='attrib'>Add-Ons</div>
          <div class='value addon'>
            <label rv-each-addon='session.custom.addons'>
              <input type='checkbox' name='addon' rv-checked='addon.checked'/>+{addon.price | money} {addon.name}
            </label>
          </div>
        </div>
      </div>
      
      <div>
        <hr/>
          <div class='tuple'>
          <div class='attrib'>Price</div>
          <div class='value'>
            { state.passes | total_price }
          </div>
        </div>
      </div>

      <div>
        <button id='checkout' rv-on-click='add_to_order'>Add this session to your order</button>
      </div>

    </div>
  </div>
`.untab(2);

SessionSlots.prototype.CSS = `
  #private_slots {}

  #private_slots .tuple .attrib {
    flex: 0 0 5em;
  }

  #private_slots .addon label {
    display: block;
    cursor: pointer;
  }

  #private_slots .slots .value {
    cursor: pointer;
  }
`.untab(2);

rivets.components['session-slots'] = { 
  template:   function()        { return SessionSlots.prototype.HTML; },
  initialize: function(el,attr) { return new SessionSlots(el,attr);   }
}
