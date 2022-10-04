function SessionForm() {

  this.state = {
    "session": { }
  }

  rivets.formatters.to_s = function(val) { typeof val == "string" ? val : JSON.stringify(val); }

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

  save(e) {
    $.post(`/models/events/${data['event'].id}/sessions`, JSON.stringify(this.state.session), function(sess) {
      this.ev_fire('after_post', JSON.parse(sess) );
    }.bind(this));  
  }

}

Object.assign( SessionForm.prototype, element);
Object.assign( SessionForm.prototype, ev_channel); 

SessionForm.prototype.HTML = `

  <div class='sessionform form'>
    <div class='tuplet'>
      <label>Start Time:</label>
      <input rv-datefield='state.session.start_time'/>
    </div>
    <div class='tuplet'>
      <label>End Time:</label>
      <input rv-datefield='state.session.end_time'/>
    </div>
    <div class='tuplet'>
      <label>Title:</label>
      <input rv-value='state.session.title'/>
    </div>
    <div class='tuplet'>
      <label>Description:</label>
      <textarea rv-value='state.session.description'></textarea>
    </div>
    <div class='tuplet'>
      <label>Individual Price Full:</label>
      <input rv-value='state.session.individual_price_full'/>
    </div>
    <div class='tuplet'>
      <label>Individual Price Member:</label>
      <input rv-value='state.session.individual_price_member'/>
    </div>
    <div class='tuplet'>
      <label>Max Capacity:</label>
      <input rv-value='state.session.max_capacity'/>
    </div>
    <div class='tuplet'>
      <label>Custom:</label>
      <textarea rv-value='state.session.custom | to_s'></textarea>
    </div>
    <div class='done' rv-on-click='this.save'>Save</div>
  </div>
  
`.untab(2);

SessionForm.prototype.CSS = `

  .sessionform {
    
  }

  .sessionform input,
  .sessionform textarea {
    font-size: 1em !important;
    width: 20em;
  }

  .sessionform .done {
    cursor: pointer;
  }

  .sesionform textarea {
    width: 20em;
    background: white;
  }

`.untab(2);
