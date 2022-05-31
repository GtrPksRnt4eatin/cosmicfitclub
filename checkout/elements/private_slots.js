function PrivateSlots(parent,attr) {

  this.session = attr['session'];

	this.state = {
      num_slots: 1,
      rental: null,
      starttime: null,
      endtime: null,
	}

	this.bind_handlers(['load_session', 'set_num_slots']);
	this.load_styles();
	//this.bind_dom();

}

PrivateSlots.prototype = {
	constructor: PrivateSlots,

    set_num_slots(e,m) {
      this.state.num_slots = parseInt(e.target.value);
      this.state.num_slots = isNaN(this.state.num_slots) ? 0 : this.state.num_slots;
      while(this.state.rental.slots.length<this.state.num_slots) {
       this.state.rental.slots.push({ customer_id: 0, customer_string: 'Add Student' }); 
      }
      while(this.state.rental.slots.length>this.state.num_slots){
        this.state.rental.slots.pop();
      }
    }
}

Object.assign( PrivateSlots.prototype, element);
Object.assign( PrivateSlots.prototype, ev_channel);

PrivateSlots.prototype.HTML = ES5Template(function(){/**
  <div id='private_slots' rv-show='session' >

    <div class='selected_timeslot'>
      <h2>{ session.title } { session.starttime | fulldate } - {session.endtime | time }</h2>
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

      <div rv-if='this.state.num_slots'>
        <hr/>
        <div class='tuple' rv-each-slot='this.state.rental.slots'>
          <div class='attrib'>
            Slot #{index | fix_index}
          <div class='value edit' rv-on-click='ctrl.choose_custy'>
            {slot.customer_string}           
          </div>
          <hr/>

          <div>
            <button id='checkout' rv-on-click='ctrl.checkout_new'>
              Pay { data.total_price | money } Now
            </button>
          </div>
        </div>
      </div>
    </div>

  </div>
**/}).untab(2);

PrivateSlots.prototype.CSS = `

`.untab(2);

rivets.components['private-slots'] = { 
  template:   function()        { return PrivateSlots.prototype.HTML; },
  initialize: function(el,attr) { return new PrivateSlots(el,attr);   }
}