function Generic() {

	this.state = {

	}

	this.bind_handlers([]);
	this.build_dom();
	this.load_styles();
	this.bind_dom();

}

Generic.prototype = {
	constructor: Generic
}

Object.assign( Generic.prototype, element);
Object.assign( Generic.prototype, ev_channel);

Generic.prototype.HTML = `

`.untab(2);

Generic.prototype.CSS = `

`.untab(2);