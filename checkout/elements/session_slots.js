function SessionSlots(parent,attr) {

  this.session         = attr['session'];
  this.customer        = attr['customer'];
  this.choose_customer = attr['choose_customer'];
  this.session_passes  = attr['passes'];

	this.state = {
    num_slots: 1,
    passes: []
	}

	this.bind_handlers(['set_num_slots', 'num_slots_selected', 'set_first_slot','clear_session', 'choose_custy','add_to_order']);
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

  check_for_existing() {
    let matches = this.session_passes.filter(function(val) { return val['session_id'] == this.session.id; }.bind(this));
    if(matches.length==0) { this.set_first_slot({ list_string: this.customer.name + ' ( ' + this.customer.email + ' )' , ...this.customer}); return; }
    this.set_num_slots(0);
    matches.forEach(function(val) {
      let idx = this.session_passes.indexOf(val);
      if(idx > -1) {
        this.state.passes.push(val);
        this.session_passes.splice(idx,1);
      }
    }.bind(this));
    this.state.num_slots = matches.length;
  },

  set_first_slot(customer) {
    this.set_num_slots(0);
    this.state.passes.push({ session_id: this.session.id, customer_id: customer.id, customer_string: customer.list_string });
    this.state.num_slots = 1;
  },

  clear_session() { this.session = null; },

  choose_custy(e,m) {
    this.choose_customer(m.slot.customer_id, function(val) { 
      Object.assign(this.state.passes[ m['%slot%'] ],{ session_id: this.session.id, ...val }); 
    }.bind(this) );
  },

  add_to_order() {
    this.session = null;
    this.session_passes.push(...this.state.passes);
    this.ev_fire('add_to_order', this.state.slots);
  }
}

Object.assign( SessionSlots.prototype, element);
Object.assign( SessionSlots.prototype, ev_channel);

SessionSlots.prototype.HTML = ES5Template(function(){/**
  <div id='private_slots' rv-show='session' >

    <div class='selected_timeslot'>
      <h2>{ session.title }</h2>
      <h3>{ session.start_time | fulldate } - {session.end_time | time }</h3>
      <span style="cursor:pointer; color: #9999FF;" rv-on-click="clear_session">change session</span>
      <br/><br/>

      <div class='tuple'>
        <div class='attrib'># People</div>
        <div class='value'>
          <select class='num_students' rv-value='state.num_slots' rv-on-change='num_slots_selected'>
            <option value="1">1</option>
            <option value="2">2</option>
          </select>  
        </div>
      </div> 

      <div rv-show='state.num_slots'>
        <hr/>
        <div class='tuple' rv-each-slot='state.passes'>
          <div class='attrib'>Slot #{index | fix_index}</div>
          <div class='value edit' rv-on-click='choose_custy'>
            {slot.customer_string}           
          </div>
          <hr/>
        </div>
        <div>
          <button id='checkout' rv-on-click='add_to_order'>Add this session to your order</button>
        </div>
      </div>
    </div>

  </div>
**/}).untab(2);

SessionSlots.prototype.CSS = `

`.untab(2);

rivets.components['session-slots'] = { 
  template:   function()        { return SessionSlots.prototype.HTML; },
  initialize: function(el,attr) { return new SessionSlots(el,attr);   }
}