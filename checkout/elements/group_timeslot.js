function GroupTimeslot(el,attr) {

  this.reservation = attr['reservation'];

  this.state = {
    durations: [
      { label: '1 hour', minutes:60 },
      { label: '1.5 hours', minutes:90 },
      { label: '2 hours', minutes:120 },
      { label: '2.5 hours', minutes:150 },
      { label: '3 hours', minutes:180 },
      { label: '3.5 hours', minutes:210 },
      { label: '4 hours', minutes:240 }
    ],
    apparatuses: [
      { label: 'Bringing My Own', value: 'none' },
      { label: 'Straps', value:'Straps' },
      { label: 'Silks', value:'Silks' },
      { label: 'Hammock', value: 'Hammock' },
      { label: 'Lyra', value:'Lyra' },
      { label: 'Spotting Belt', value:'spotting_belt' }
    ]     
  }

	this.bind_handlers([]);
	this.load_styles();

}

GroupTimeslot.prototype = {
	constructor: GroupTimeslot
}

Object.assign( GroupTimeslot.prototype, element);
Object.assign( GroupTimeslot.prototype, ev_channel);

GroupTimeslot.prototype.HTML = `
  <h3>Edit Your Reservation</h3>
  <div class='tuple' rv-if='reservation.tag' >
    <div class='attrib'>Confirmation Tag:</div>
    <div class='value'>{ reservation.tag }</div>
  </div>
  <div class='tuple'>
    <div class='attrib'>Timeslot:</div>
    <div class='value pointer' rv-on-click='clear_starttime'>
        { reservation.start_time | dateformat 'ddd MMM D h:mm A' } - { reservation.end_time | dateformat 'h:mm A' }
    </div>
  </div>
  <div class='tuple'>
    <div class='attrib'>Duration</div>
    <div class='value'>
      <select rv-on-change='update_endtime' rv-value='rental.duration' >
        <option rv-each-duration='state.durations' value='reservation.duration'> {duration.label} </option>
      </select>
    </div>
  </div>
  <div class='tuple'>
    <div class='attrib'>Apparatus</div>
    <div class='value'>
      <select rv-value='reservation.activity' >
        <option rv-each-apparatus='state.apparatuses' value='apparatus.value'> {apparatus.label} </option>
      </select>
    </div>
  </div>
  <div class='tuple'>
    <div class='attrib'>Rigging Notes</div>
    <div class='value'>
      <textarea rv-value='reservation.rigging_notes' ></textarea>
    </div>
  </div>
  <div class='tuple'>
    <div class='attrib'># of People</div>
    <div class='value'>
      <input type='number' rv-value='reservation.num_people' min='1' />
    </div>
  </div>
  <div>
    <hr>
    <div class='tuple' rv-each-slot='reservation.slots' >
        <div class='attrib'>Slot \#{ $index | fix_index }</div>
        <div class='value pointer' rv-on-click='choose_custy'>
            { slot.customer_string }
        </div>
    </div>
  </div>
  <hr>
  <button rv-on-click='confirm_reservation'> Request This Timeslot</button>
`.untab(2);

GroupTimeslot.prototype.CSS = `

`.untab(2);

rivets.components['group-timeslot'] = {
  template:   function()        { return GroupTimeslot.prototype.HTML; },
  initialize: function(el,attr) { return new GroupTimeslot(el,attr);   }
}