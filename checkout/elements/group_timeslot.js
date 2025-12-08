function GroupTimeslot(el,attr) {

  this.res = attr['reservation'];

  this.opts = {
    durations: [
      { label: '1 hour',    value:60 },
      { label: '1.5 hours', value:90 },
      { label: '2 hours',   value:120 },
      { label: '2.5 hours', value:150 },
      { label: '3 hours',   value:180 },
      { label: '3.5 hours', value:210 },
      { label: '4 hours',   value:240 }
    ],
    apparatuses: [
      { label: 'Bringing My Own', value: 'none' },
      { label: 'Straps',          value: 'Straps' },
      { label: 'Silks',           value: 'Silks' },
      { label: 'Hammock',         value: 'Hammock' },
      { label: 'Lyra',            value: 'Lyra' },
      { label: 'Spotting Belt',   value: 'Spotting Belt' }
    ]     
  }

  rivets.formatters.fix_index = function(val, arg) { return val + 1; }

	this.bind_handlers(['set_num_slots','update_endtime']);
	this.load_styles();

}

GroupTimeslot.prototype = {
	constructor: GroupTimeslot,

  set_num_slots: function(e,m) {
    let num_slots = parseInt(e.target.value);
    this.res.num_slots = isNaN(num_slots) ? 0 : num_slots;
    while( this.res.slots.length < num_slots ) { this.res.slots.push({ customer_id: 0, customer_string: '' }); }
    while( this.res.slots.length > num_slots ) { this.res.slots.pop(); }
  },

  update_endtime: function(e,m) {
    let start = this.res.start_time.getTime();
    let duration_ms = this.res.duration * 60000;
    this.res.end_time = new Date( start + duration_ms );
  },

  choose_custy: function(e,m) {  

}

Object.assign( GroupTimeslot.prototype, element);
Object.assign( GroupTimeslot.prototype, ev_channel);

GroupTimeslot.prototype.HTML = `
  <h3>Edit Your Reservation</h3>
  <div class='tuple' rv-if='res.tag' >
    <div class='attrib'>Confirmation Tag:</div>
    <div class='value'>{ res.tag }</div>
  </div>
  <div class='tuple'>
    <div class='attrib'>Timeslot:</div>
    <div class='value pointer' rv-on-click='clear_starttime'>
        { res.start_time | dateformat 'ddd MMM D h:mm A' } - { res.end_time | dateformat 'h:mm A' }
    </div>
  </div>
  <div class='tuple'>
    <div class='attrib'>Duration</div>
    <div class='value'>
      <select rv-on-change='update_endtime' rv-value='res.duration' >
        <option rv-each-duration='opts.durations' rv-value='duration.value'> {duration.label} </option>
      </select>
    </div>
  </div>
  <div class='tuple'>
    <div class='attrib'>Apparatus</div>
    <div class='value'>
      <select rv-value='res.activity' >
        <option rv-each-apparatus='opts.apparatuses' rv-value='apparatus.value'> {apparatus.label} </option>
      </select>
    </div>
  </div>
  <div class='tuple'>
    <div class='attrib'>Rigging Notes</div>
    <div class='value'>
      <textarea rv-value='res.rigging_notes'></textarea>
    </div>
  </div>
  <div class='tuple'>
    <div class='attrib'># of People</div>
    <div class='value'>
      <input type='number' rv-value='res.num_people' min='1' />
    </div>
  </div>
  <div>
    <hr>
    <div class='tuple' rv-each-slot='res.slots' >
        <div class='attrib'>Slot \#{ $index | fix_index }</div>
        <div class='value pointer' rv-on-click='choose_custy'>
            { slot.customer_string }
        </div>
    </div>
  </div>
  <hr>
  <button rv-on-click='confirm_reservation'>Request This Timeslot</button>
`.untab(2);

GroupTimeslot.prototype.CSS = `

`.untab(2);

rivets.components['group-timeslot'] = {
  template:   function()        { return GroupTimeslot.prototype.HTML; },
  initialize: function(el,attr) { return new GroupTimeslot(el,attr);   }
}