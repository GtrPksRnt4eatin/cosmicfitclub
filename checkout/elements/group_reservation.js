function GroupReservation(perent,attr) {
  this.reservation = attr['reservation'];
  this.reservation.total_price = this.reservation.slots?.reduce( function(total, slot) { 
    let duration = slot.duration || rivets.formatters.duration(res.start_time, res.end_time);
    return(total + (duration / 60 * 1200));
  }, 0) || 0;

  rivets.formatters.count = function(val) { return val ? val.length : 0; }
  rivets.formatters.slot_price = function(slot) {
    let duration = slot.duration || rivets.formatters.duration(this.reservation.start_time, this.reservation.end_time);
    return( rivets.formatters.money(duration / 60 * 1200) ); 
  }.bind(this)

  this.bind_handlers(['add_custy','edit_custy','del_custy', 'delete', 'price', 'checkout']);
  this.load_styles();
}

GroupReservation.prototype = {
  constructor: GroupReservation,

  add_custy(e,m) {
    if(this.reservation.slots.length >= 4) { return; }
    this.reservation.slots.push({ customer_id: 0, customer_string: '' });
    this.edit_custy(null, { slot: this.reservation.slots.slice(-1) });
  },

  edit_custy(e,m) {
    this.ev_fire('choose_custy', [m.slot.customer_id, function(custy) {
      m.slot.customer_id = custy.id;
      m.slot.customer_string = custy.label;  
    }.bind(this)])
  },

  del_custy(e,m) {
    let idx = this.reservation.slots.indexOf(m.slot);
    if(idx = -1) { return; }
    this.reservation.slots.splice(idx,1);
  },

  delete: function(e,m) {
    $.del('/models/groups/' + m.reservation.id)
     .success( function() { history.back(); })
     .fail(function() { alert('Delete Failed'); });
  },
  
  price: function() { 
    return this.reservation.slots?.reduce( function(total, slot) { 
      let duration = slot.duration || rivets.formatters.duration(this.reservation.start_time, this.reservation.end_time);
      return(total + (duration / 60 * 1200));
    }, 0) || 0; 
  },

  checkout: function(e,m) {

  }
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
      <div class='attrib'> People: </div>
      <table class='reflections'>
        <tr>
          <th colspan='2'> People </th>
          <th>
            <div class='add' rv-on-click='add_custy'></div>
          </th>
        </tr>
        <tr rv-each-slot='reservation.slots'>
          <td> { slot.customer_string } </td>
          <td> { slot | slot_price } </td>
          <td class='nobg'>
            <div class='edit' rv-on-click='edit_custy'></div>
            <div class='delete' rv-on-click='del_custy'></div>        
          </td>
        </tr>
        <tr>
          <th>Total Price:</th>
          <th>{ price | call }</th>
        </tr>
      </table>
    </div>
  </div>
`.untab(2);

GroupReservation.prototype.CSS = `
  .group_reservation .attrib {
    width: 10em;
  }

  .group_reservation table.reflections td, 
  .group_reservation table.reflections th {
    color: black;
    background: rgba(255,255,255,0.5);
    border-radius: 0.5em;
  }

`.untab(2);

rivets.components['group-reservation'] = {
  template:  function()         { return GroupReservation.prototype.HTML; },
  initialize: function(el,attr) { return new GroupReservation(el,attr);   }
}
