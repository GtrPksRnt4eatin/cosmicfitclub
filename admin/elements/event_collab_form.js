function EventCollabForm() {

    this.state = {
      collab: { }
    }
  
    rivets.formatters.to_s = function(val) { return(typeof val == "string" ? val : JSON.stringify(val)); }
  
    this.bind_handlers(['save']);
    this.build_dom();
    this.load_styles();
    this.bind_dom();
  }
  
  EventCollabForm.prototype = {
  
    constructor: EventCollabForm,
  
    show_new()  { 
        this.state.collab = { "id": 0 };
        this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} ); 
    },
  
    show_edit(collab) { 
        this.state.collab = collab;
        this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} ); 
    },
  
    save(e) {
      $.post(`/models/events/${data['event'].id}/collaborations`, JSON.stringify(this.state.session), function(sess) {
        this.ev_fire('after_post', JSON.parse(sess) );
      }.bind(this));  
    }
  
  }
  
  Object.assign( EventCollabForm.prototype, element);
  Object.assign( EventCollabForm.prototype, ev_channel); 
  
  EventCollabForm.prototype.HTML = `
  
    <div class='eventcollabform form'>
      <div class='tuplet'>
        <label>Collaborator:</label>
        <custy-selector></custy-selector>
      </div>
      <div class='tuplet'>
        <label>Phone:</label>
        <input rv-value='state.collab.phone' />
      </div>
      <div class='tuplet'>
        <label>Notify:</label>
        <input rv-value='state.collab.notify'/>
      </div>
      <div class='tuplet'>
        <label>Stripe ID:</label>
        <input rv-value='state.collab.stripe_id'/>
      </div>
      <div class='tuplet'>
        <label>Percentage:</label>
        <input rv-value='state.collab.percent'/>
      </div>
      <div class='done' rv-on-click='this.save'>Save</div>
    </div>
    
  `.untab(2);
  
  EventCollabForm.prototype.CSS = `
  
    .eventcollabform input {
      font-size: 1em !important;
      width: 20em;
    }
  
    .eventcollabform .done {
      cursor: pointer;
    }
  
  `.untab(2);