function RentalForm() {

  this.state = {
    rental: null,
    hours: [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]
  }

  this.bind_handlers(['save']);
  this.build_dom();
  this.bind_dom();
  this.load_styles();
}

RentalForm.prototype = {

  constructor: RentalForm,

  show_new()  { 
    this.state.rental = { "id": 0 };
    this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} ); 
  },

  show_edit(rental) { 
    this.state.rental = rental;
    this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} ); 
  },

  save(e) {
    $.post('/models/rentals', this.state.rental)
     .done( function(rental) { this.ev_fire('after_post', JSON.parse(rental) ); }.bind(this) )
     .fail( function()       { alert("Failed to Create Rental!"); } ) 
  }

}

Object.assign( RentalForm.prototype, element);
Object.assign( RentalForm.prototype, ev_channel); 

RentalForm.prototype.HTML = `
  
  <div class='RentalForm form'>
    <h3>Create New Rental</h3>
    <div class='tuplet'>
      <label>Start Time:</label>
      <input id='starttime' class='time' rv-datefield='state.rental.start_time' />
    </div>
    <div class='tuplet'>
      <label>Duration:</label>
      <select rv-value='state.rental.duration_hours'>
        <option rv-each-val='state.hours' rv-value='val'>
          {val} hours
        </option>
      </select>
    </div>
    <div class='tuplet'>
      <label>Title</label>
      <input rv-value='state.rental.title'></input>
    </div>
    <div class='done' rv-on-click='this.save'>Save</div>
  </div>

`.untab(2);

RentalForm.prototype.CSS = `

  .RentalForm {
    
  }

  .RentalForm label {
    vertical-align: middle;
    width: 8em;
    display: inline-block;
    text-align: right;
  }

  .RentalForm .tuplet {
    margin: .2em 0;
  }

  .RentalForm .flatpickr-time input {
    width: 4em !important;
  }

  .RentalForm input,
  .RentalForm textarea {
    font-size: 1em !important;
    width: 20em;
  }

  .RentalForm .done {
    cursor: pointer;
  }

  .RentalForm select {
  	font-size: inherit;
  	font-family: inherit;
  	width: 20em;
  	padding: .2em;
  }

  .RentalForm .flatpickr-calendar.noCalendar {
    display: inline-block;
    font-size: inherit;
    width: 20em;
    vertical-align: middle;
  }

  .RentalForm .flatpickr-calendar.arrowTop:before,
  .RentalForm .flatpickr-calendar.arrowTop:after {
    display: none !important;
  }

  .RentalForm .done {
    margin-top: 1em;
    padding: .5em;
    cursor: pointer;
    background: rgba(255,255,255,0.2);
  }

`.untab(2);