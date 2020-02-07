function EditTextArray() {

  this.state = {
  	title: "",
  	value: [],
  	callback: null
  }

  this.bind_handlers(['show','add_line','rem_line','save','cancel','change_line']);
  this.build_dom();
  this.bind_dom();
  this.load_styles();

}

EditTextArray.prototype = {

	constructor: EditTextArray,

	show: function(title, value, callback) {
	  this.state.title = title || "";
	  this.state.value = value || [];
	  this.state.callback = callback;
      this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} );
	},

	add_line: function(e,m) {
    this.state.value.push("");
	},

	rem_line: function(e,m) {
       var x = 5;
	},

	save: function() {
	  this.state.callback.call(null,this.state.value);
	  this.state.callback = null;
	  this.ev_fire('done', this.state.value);
	},

	cancel: function() {
      this.state.title = null;
      this.state.value = null;
      this.state.callback = null;
	},

  change_line: function(e,m) {
    this.state.value[m.index] = e.target.value;
  }

}

Object.assign( EditTextArray.prototype, element);
Object.assign( EditTextArray.prototype, ev_channel);

EditTextArray.prototype.HTML = ES5Template(function(){/**
  
  <div class='edit_text_array form' >
    <h3>{state.title}</h3>
    <div class='text_line' rv-each-line="state.value">
      <input rv-value='line' rv-on-change='this.change_line'></input>
      <div class='del' rv-on-click='this.rem_line'></div>
    </div>
    <button rv-on-click='this.add_line'>Add Line</button>
    <button rv-on-click='this.save'>Save</button>
  </div>

**/}).untab(2)

EditTextArray.prototype.CSS = ES5Template(function(){/**

  .edit_text_array h3 {
    margin: 0 0 1em 0;
  }

  .edit_text_array .text_line {
    position: relative;
  }

  .edit_text_array .text_line .del {
    background-image: url('/close.svg');
    cursor: pointer;
    width: 1em;
    height: 1em;
    background-size: contain;
    transition: all .2s ease-in-out;
    display: inline-block;
    position: absolute;
    top: 0.25em;
    right: 0.25em;
  }

  .edit_text_array .text_line .del:hover {
    transform: scale(1.1);
  }

  .edit_text_array input {
	  background: rgba(255,255,255,0.5);
    color: black;
    padding: 0.25em 1em;
    border-radius: 0.5em;
    width: 15em;
  }

  .edit_text_array button {
    font-size: 1em;
    border-radius: 0.5em;
    width: 15em;
    margin: 1em 0 0 0;
  }

**/}).untab(2)