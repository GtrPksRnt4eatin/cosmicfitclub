function EventCollabForm() {

    this.state = {
      collab: { },
      customer: { }
    }
  
    rivets.formatters.to_s = function(val) { return(typeof val == "string" ? val : JSON.stringify(val)); }
  
    this.bind_handlers(['save', 'show_new', 'show_edit', 'load_staff_info']);
    this.build_dom();
    this.load_styles();
    this.bind_dom();
  }
  
  EventCollabForm.prototype = {
  
    constructor: EventCollabForm,
  
    show_new(event_id)  { 
        this.state.collab = { "event_id": event_id };
        this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} ); 
    },
  
    show_edit(collab) { 
        this.state.collab = collab;
        this.load_staff_info(collab.customer);
        this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} ); 
    },

    load_staff_info(custy) {
      $.get(`/models/customers/${custy.id}/staffinfo`, function(data) {
        this.state.collab.customer_id = data.id;
        this.state.customer = data;
      }.bind(this))
    },
  
    save(e) {
      $.post(`/models/events/collabs`, this.state.collab, function(collab) {
        this.ev_fire('after_post', JSON.parse(collab) );
      }.bind(this));  
    }
  
  }
  
  Object.assign( EventCollabForm.prototype, element);
  Object.assign( EventCollabForm.prototype, ev_channel); 
  
  EventCollabForm.prototype.HTML = `
  
    <div class='eventcollabform form'>
      <div class='tuplet'>
        <label>Collaborator:</label>
        <custy-selector onchange='this.load_staff_info'></custy-selector>
      </div>
      <div class='tuplet'>
        <label>Phone:</label>
        <input disabled rv-value='state.customer.phone' />
      </div>
      <div class='tuplet'>
        <label>Stripe ID:</label>
        <input disabled rv-value='state.customer.staff.stripe_connect_id'/>
      </div>
      <div class='tuplet'>
        <label>Notify:</label>
        <input id='notify-toggle' class='toggle' type='checkbox' rv-value='state.collab.notify'/>
        <label for='notify-toggle' class='toggle'></label>
      </div>
      <div class='tuplet'>
        <label>Percentage:</label>
        <input class='percent' type='number' max='100' step='0.5' min='0' rv-value='state.collab.percent'/>
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

    .eventcollabform custy-selector {
      width: 100%;
    }

    .eventcollabform .percent {
      width: 4em;
    }

    .eventcollabform .percent:after {
      content: '%';
    }
  
  `.untab(2);