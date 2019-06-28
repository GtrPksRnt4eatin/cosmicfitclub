function ClassSelector() {

  this.state = {
    "price": { },
    "sessions": []
  }

  this.bind_handlers(['save']);
  this.build_dom();
  this.load_styles();
  this.bind_dom();
}

ClassSelector.prototype = {
  constructor: ClassSelector,

  show_new()  { 
    this.state.sessions = data.event.sessions;
  	this.state.price = { "id": 0 };
  	this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} ); 
  },

  show_edit(price) { 
    this.state.sessions = data.event.sessions;
  	this.state.price = price;
  	this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} ); 
  },

  save(e) {
    $.post(`/models/events/${data['event'].id}/prices`, JSON.stringify(this.state.price), function(price) {
      this.ev_fire('after_post', JSON.parse(price) );
    }.bind(this));
  }
}

Object.assign( ClassSelector.prototype, element);
Object.assign( ClassSelector.prototype, ev_channel); 

ClassSelector.prototype.HTML = ES5Template(function(){/**
  <div class='ClassSelector form'>
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
      <label>Member Price:</label>
      <input rv-value='state.price.member_price'/>
    </div>
    <div class='tuplet'>
      <label>Full Price:</label>
      <input rv-value='state.price.full_price'></textarea>
    </div>
    <div class='done' rv-on-click='this.save'>Save</div>
  </div>
**/}).untab(2);

ClassSelector.prototype.CSS = ES5Template(function(){/**
  .ClassSelector { }

  .ClassSelector input,
  .ClassSelector textarea {
    font-size: 1em !important;
    width: 20em;
  }

  .ClassSelector select {
    width: 20em;
    font-size: 1em;
    vertical-align: middle;
    font-family: "Industry-Light";
  }

  .ClassSelector .done {
    cursor: pointer;
  }

  .ClassSelector label {
    width: 7em
  }
**/}).untab(2);
