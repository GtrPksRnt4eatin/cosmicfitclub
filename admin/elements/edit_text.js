function EditText() {
  
  this.state = {
  	title: "", 
    value: "",
    callback: null,
    long: false
  }

  this.bind_handlers(['show','show_long','save','cancel']);
  this.build_dom();
  this.bind_dom();
  this.load_styles();

}

EditText.prototype = {

	constructor: EditText,

	show: function(title, value, callback) {
    this.state.long  = false;
	  this.state.title = title;
	  this.state.value = value;
	  this.state.callback = callback;
      this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} );
	},

  show_long: function(title, value, callback) {
    this.state.long = true;
    this.show(title,value,callback);
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

Object.assign( EditText.prototype, element);
Object.assign( EditText.prototype, ev_channel);

EditText.prototype.HTML = ES5Template(function(){/**
  <div class='edit_text form' >
    <h3>{state.title}</h3>
    <div>
      <input rv-unless='state.long' rv-value='state.value'></input>
      <textarea rv-if='state.long'  rv-value='state.value'></input>
    </div>
    <button rv-on-click='this.save'>Save</button>
  </div>
**/}).untab(2);

EditText.prototype.CSS = ES5Template(function(){/**
  
  .edit_text input,
  .edit_text textarea {
	background: rgba(255,255,255,0.5);
    color: black;
    padding: 0.25em 1em;
    border-radius: 0.5em;
  }

**/}).untab(2);