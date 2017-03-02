function PriceForm() {

  this.state = {
    "session": { }
  }

  this.bind_handlers(['save']);
  this.build_dom();
  this.load_styles();
  this.bind_dom();
}

PriceForm.prototype = {
  constructor: PriceForm,

  show_new()  { 
  	this.state.price = { "id": 0 };
  	this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} ); 
  },

  show_edit(price) { 
  	this.state.price = price;
  	this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} ); 
  },

  save(e) {
    $.post(`/models/events/${data['event'].id}/prices`, JSON.stringify(this.state.price), function(price) {
      this.ev_fire('after_post', price );
    }.bind(this));
  }

}

Object.assign( PriceForm.prototype, element);
Object.assign( PriceForm.prototype, ev_channel); 

PriceForm.prototype.HTML = `
  <div class='PriceForm form'>
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
    <div class='done' rv-on-click='this.save'>Save</div>
  </div>
`.untab(2);

PriceForm.prototype.CSS = `
  .PriceForm {
    
  }

  .PriceForm input,
  .PriceForm textarea {
    font-size: 1em !important;
    width: 20em;
  }

  .PriceForm .done {
    cursor: pointer;
  }

`.untab(2);
