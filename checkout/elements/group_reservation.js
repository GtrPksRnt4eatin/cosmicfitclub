function GroupReservation(perent,attr) {
  this.reservation = attr['reservation'];

  rivets.formatters.count = function(val) { return val ? val.length : 0; }

  this.bind_handlers([]);
  this.load_styles();
}

GroupReservation.prototype = {
	constructor: GroupReservation
}

Object.assign( GroupReservation.prototype, element);
Object.assign( GroupReservation.prototype, ev_channel);

GroupReservation.prototype.HTML = `
  <div class='group_reservation'>
    <div class='tuple'>
      <div class='attrib'>Reservation Tag:</div>
      <div class='value'>{reservation.tag}</div>
    </div>
    <div class='tuple'>
      <div class='attrib'> Start: </div>
      <div class='value'> {reservation.start_time | fulldate} </div>
    </div>
    <div class='tuple'>
      <div class='attrib'> End: </div>
      <div class='value'> {reservation.end_time | fulldate} </div>
    </div>
    <div class='tuple'>
      <div class='attrib'> Duration: </div>
      <div class='value'> {reservation.start_time | duration reservation.end_time } Minutes </div>
    </div>
    <div class='tuple'>
      <div class='attrib'> Apparatus: </div>
      <div class='value'> {reservation.activity} </div>
    </div>
    <div class='tuple'>
      <div class='attrib'>Rigging Notes:</div>
      <div class='value'>{reservation.note}</div>
    </div>
    <div class='tuple'>
      <div class='attrib'># of Slots (max 4):</div>
      <div class='value'>
        <select rv-value='reservation.slots | count'>
          <option value="0">0</option>
          <option value="1">1</option>
          <option value="2">2</option>
          <option value="3">3</option>
          <option value="4">4</option>
        </select>
      </div>
    </div>
    <div class='tuple' rv-each-slot="reservation.slots">
      <div class='attrib'>#{index | fix_index}</div>
      <div class='value edit'>{slot.customer_string}</div>
    </div>  
  </div>
`.untab(2);

GroupReservation.prototype.CSS = `
  .group_reservation .attrib {
    width: 10em;
  }
`.untab(2);

rivets.components['group-reservation'] = {
  template:  function()         { return GroupReservation.prototype.HTML; },
  initialize: function(el,attr) { return new GroupReservation(el,attr);   }
}