function PriceForm() {

  this.state = {
    "price": { },
    "sessions": [],
    "sliding": false
  }

  rivets.formatters.to_s = function(val) { return(typeof val == "string" ? val : JSON.stringify(val)); }

  this.bind_handlers(['save', 'clear_before', 'clear_after']);
  this.build_dom();
  this.load_styles();
  this.bind_dom();
}

PriceForm.prototype = {
  constructor: PriceForm,

  show_new()  { 
    this.state.sliding = data.event.mode == "sliding";
    this.state.sessions = data.event.sessions;
  	this.state.price = { "id": 0 };
  	this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} ); 
  },

  show_edit(price) {
    this.state.sliding = data.event.mode == "sliding";
    this.state.sessions = data.event.sessions;
  	this.state.price = price;
  	this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} ); 
  },

  save(e) {
    $.post(`/models/events/${data['event'].id}/prices`, JSON.stringify(this.state.price), function(price) {
      this.ev_fire('after_post', JSON.parse(price) );
    }.bind(this));
  },

  clear_before(e) {
    this.state.price.available_before = null;
  },

  clear_after(e) {
    this.state.price.available_after = null;
  }
}

Object.assign( PriceForm.prototype, element);
Object.assign( PriceForm.prototype, ev_channel); 

PriceForm.prototype.HTML = `
  <div class='PriceForm form'>
    <div class='tuplet'>
      <label>Title:</label>
      <input rv-value='state.price.title'/>
    </div>
    <div class='tuplet'>
      <label>Sessions:</label>
      <select multiple rv-value='state.price.included_sessions'>
        <option rv-each-sess='state.sessions' rv-value='sess.id'>{sess.title}</option>
      </select>
    </div>
    <div class='tuplet'>
      <label>Available Before</label>
      <input class="date" rv-datefield='state.price.available_before' />
      <button class="clear" rv-on-click='this.clear_before'>Clear</button>
    </div>
    <div class='tuplet'>
      <label>Available After</label>
      <input class="date" rv-datefield='state.price.available_after' />
      <button class="clear" rv-on-click='this.clear_after'>Clear</button>
    </div>
    <div class='tuplet'>
      <label>Max Quantity</label>
      <input type='number' rv-value='state.price.max_quantity' />
    </div>
    <div class='tuplet'>
      <label>Member Price:</label>
      <input rv-value='state.price.member_price'/>
    </div>
    <div class='tuplet'>
      <label>Full Price:</label>
      <input rv-value='state.price.full_price'/>
    </div>
    <div class='tuplet'>
      <label>Num Passes</label>
      <input type='number' rv-value='state.price.num_passes'/>
    </div>
    <div rv-show='state.sliding'>
      <label>Sliding Scale</label>
      <textarea rv-value='state.price.sliding | to_s'></textarea>
    </div>
    <div class='done' rv-on-click='this.save'>Save</div>
  </div>
`.untab(2);

PriceForm.prototype.CSS = `
  .PriceForm { }

  .PriceForm input,
  .PriceForm textarea {
    font-size: 1em !important;
    width: 20em;
  }

  .PriceForm input.date {
    width: 15em;
  }

  .PriceForm button.clear {
    width: 5em;
  }



  .PriceForm select {
    width: 20em;
    font-size: 1em;
    vertical-align: middle;
    font-family: "Industry-Light";
  }

  .PriceForm .done {
    cursor: pointer;
  }

  .PriceForm label {
    width: 8em
  }
`.untab(2);
