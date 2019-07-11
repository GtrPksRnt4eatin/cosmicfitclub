function EditShortText() {
  
  this.state = {
  	title: "", 
    value: "",
    callback: null
  }

  this.bind_handlers(['show','save','cancel']);
  this.build_dom();
  this.bind_dom();
  this.load_styles();

}

EditShortText.prototype = {

	constructor: EditShortText,

	show: function(title, value, callback) {
	  this.state.title = title;
	  this.state.value = value;
	  this.state.callback = callback;
      this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} );
	},

	save: function() {
	  this.state.callback.call(null,this.state.value);
	  this.state.callback = null;
	  this.ev_fire('done', value);
	},

	cancel: function() {
      this.state.title = null;
      this.state.value = null;
      this.state.callback = null;
	}
}

Object.assign( EditShortText.prototype, element);
Object.assign( EditShortText.prototype, ev_channel);

EditShortText.prototype.HTML = ES5Template(function(){/**
  <div class='edit_short_text form' >
    <input rv-value='state.value'>
    <button rv-on-click='this.save'>Save</button>
  </div>
**/}).untab(2);

EditShortText.prototype.CSS = ES5Template(function(){/**

**/}).untab(2);