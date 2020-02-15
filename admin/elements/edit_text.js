function EditText() {
  
  this.state = {
  	title: "", 
    value: "",
    callback: null,
    validation_callback: null,
    validation_errs: [],
    long: false
  }

  this.bind_handlers(['show','show_long','save','cancel','validate']);
  this.build_dom();
  this.bind_dom();
  this.load_styles();

}

EditText.prototype = {

	constructor: EditText,

	show: function(title, value, callback, validation_callback) {
	  this.state.title = title;
	  this.state.value = value;
	  this.state.callback = callback;
    this.state.validation_callback = validation_callback;
    this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} );
	},

  show_long: function(title, value, callback, validation_callback) {
    this.state.long = true;
    this.show(title,value,callback, validation_callback);
  },

	save: function() {
    if(!this.validate()) { $(this.dom).shake(); return; }
	  this.state.callback.call(null,this.state.value);
    this.state.long = false
	  this.state.callback = null;
	  this.ev_fire('done', this.state.value);
	},

	cancel: function() {
    this.state.long = false;
    this.state.title = null;
    this.state.value = null;
    this.state.callback = null;
	},

  validate: function() {
    if(!this.state.validation_callback) { return true; }
    this.state.validation_errs = this.state.validation_callback.call(null,this.state.value);
    return this.state.validation_errs.length==0;
  }
}

Object.assign( EditText.prototype, element);
Object.assign( EditText.prototype, ev_channel);

EditText.prototype.HTML = ES5Template(function(){/**
  <div class='edit_text form' >
    <h3>{state.title}</h3>
    <div>
      <input rv-unless='state.long' rv-value='state.value' rv-on-input='this.validate'></input>
      <textarea rv-if='state.long'  rv-value='state.value' rv-on-input='this.validate'></textarea>
    </div>
    <div class='errors'>
      <div class='err' rv-each-err='state.validation_errs'> { err } </div>
    </div>
    <button rv-on-click='this.save'>Save</button>
  </div>
**/}).untab(2);

EditText.prototype.CSS = ES5Template(function(){/**
  
  .edit_text h3 {
    margin: 0 0 1em 0;
  }

  .edit_text input,
  .edit_text textarea {
	background: rgba(255,255,255,0.5);
    color: black;
    fonty-size: 1em;
    padding: 0.25em 1em;
    border-radius: 0.5em;
    width: 20em;
  }

  .edit_text textarea {
    height: 10em;
  }

  .edit_text button {
    font-size: 1em;
    border-radius: 0.5em;
    width: 15em;
    margin: 1em 0 0 0;
  }

  .edit_text .err {
    margin-top: 0.5em;
    font-size: 0.8em;
    color: rgb(255,0,0);
    font-family: 'Industry-Bold';
    text-shadow: 0 0 0.5em black;
  }

**/}).untab(2);