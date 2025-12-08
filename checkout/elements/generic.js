function GroupTimeslot() {

	this.state = {

	}

	this.bind_handlers([]);
	this.build_dom();
	this.load_styles();
	this.bind_dom();

}

GroupTimeslot.prototype = {
	constructor: GroupTimeslot
}

Object.assign( GroupTimeslot.prototype, element);
Object.assign( GroupTimeslot.prototype, ev_channel);

GroupTimeslot.prototype.HTML = `

`.untab(2);

GroupTimeslot.prototype.CSS = `

`.untab(2);

rivets.components['generic-element'] = {
  template:  function()         { return GroupTimeslot.prototype.HTML; },
  initialize: function(el,attr) { return new GroupTimeslot(el,attr);   }
}