function SessionSlots(parent,attr) {

  this.session         = attr['session'];
  this.customer        = attr['customer'];
  this.choose_customer = attr['choose_customer'];
  this.session_passes  = attr['session_passes'];

	this.state = {
    num_slots: 1,
    passes: []
	}

	this.bind_handlers(['set_num_slots', 'clear_session', 'choose_custy','add_to_order']);
	this.load_styles();
}

SessionSlots.prototype = {
	constructor: SessionSlots,

  set_num_slots(e,m) {
    this.state.num_slots = parseInt(e.target.value);
    this.state.num_slots = isNaN(this.state.num_slots) ? 1 : this.state.num_slots;
    while(this.state.passes.length<this.state.num_slots) {
      this.state.passes.push({ session_id: this.session.id, customer_id: 0, customer_string: 'Add Student' }); 
    }
    while(this.state.passes.length>this.state.num_slots){
      this.state.passes.pop();
    }
  },

  clear_session() { this.session = null; },

  choose_custy(e,m) {
    this.choose_customer(m.slot.customer_id, function(val) { this.state.passes[index] = { session_id: this.session.id, ...val } } );
  },

  add_to_order() {
    this.session = null;
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
          <select class='num_students' rv-on-change='set_num_slots'>
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