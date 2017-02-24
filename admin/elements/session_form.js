function SessionForm() {

  this.state = {
    "session": { }
  }

  this.bind_handlers(['save']);
  this.build_dom();
  this.load_styles();
  this.bind_dom();
}

SessionForm.prototype = {
  constructor: SessionForm,

  show_new()  { 
  	this.state.session = { "id": 0 };
  	this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} ); 
  },

  show_edit(sess) { 
  	this.state.session = sess;
  	this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} ); 
  },

  save() {

  }

}

Object.assign( SessionForm.prototype, element);
Object.assign( SessionForm.prototype, ev_channel); 

SessionForm.prototype.HTML = `
  <div class='sessionform'>
    <div class='tuplet'>
      <label>Start Time:</label>
      <input rv-datefield='state.session.starttime'/>
    </div>
    <div class='tuplet'>
      <label>End Time:</label>
      <input rv-datefield='state.session.endtime'/>
    </div>
    <div class='tuplet'>
      <label>Title:</label>
      <input rv-value='state.session.title'/>
    </div>
    <div class='tuplet'>
      <label>Description:</label>
      <textarea rv-value='state.session.description'/>
    </div>
    <div class='done' rv-on-click='this.save'>Save</div>
  </div>
`.untab(2);