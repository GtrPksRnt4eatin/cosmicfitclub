function GroupReservation(perent,attr) {
  this.reservation = attr['reservation'];
  this.bind_handlers([]);
  this.load_styles();
}

GroupReservation.prototype = {
	constructor: GroupReservation
}

Object.assign( GroupReservation.prototype, element);
Object.assign( GroupReservation.prototype, ev_channel);

GroupReservation.prototype.HTML = `

`.untab(2);

GroupReservation.prototype.CSS = `

`.untab(2);

rivets.components['group-reservation'] = {
  template:  function()         { return GroupReservation.prototype.HTML; },
  initialize: function(el,attr) { return new GroupReservation(el,attr);   }
}