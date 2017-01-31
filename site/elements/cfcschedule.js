function Schedule(parent) {
  
  this.state = {
  	current_date: moment(),
    formatted_date: function() { return this.current_date.format('ddd MMM Do YYYY'); }
  }

  //this.bind_handlers( [ this.prev_day, this.next_day ] );
  this.bind_handlers2();
  this.build_dom(parent);
  this.load_styles();
  this.bind_dom();
  this.set_formatted_date();
}

Schedule.prototype = {

  constructor: Schedule,

  bind_handlers2() {
    this.prev_day = this.prev_day.bind(this);
    this.next_day = this.next_day.bind(this);
  },

  prev_day() { this.state.current_date.subtract(1, 'days'); this.set_formatted_date(); },
  next_day() { this.state.current_date.add(1, 'days');      this.set_formatted_date(); },

  set_formatted_date() {
    this.state.formatted_date = this.state.current_date.format('ddd MMM Do YYYY');
    this.ev_fire( 'day_of_week', this.state.current_date.format('ddd') );
  }

}

Object.assign( Schedule.prototype, element );
Object.assign( Schedule.prototype, ev_channel );

Schedule.prototype.HTML = `
  <div id='Schedule'>
    <div class='header'>
      <span rv-on-click='this.prev_day'> < </span>
        <div class='current_date'>
          { state.formatted_date }
        </div>
      <span rv-on-click='this.next_day'> > </span>
    </div>
  </div>
`.untab(2);

Schedule.prototype.CSS = `

  #Schedule .current_date {
    display: inline-block;
  }

  #Schedule .header span {
    cursor: pointer;
    padding: 0 1em;
  }

`.untab(2);