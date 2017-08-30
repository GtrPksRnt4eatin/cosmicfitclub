function Schedule(parent) {
  
  this.state = {
  	current_date: moment().startOf('day'),
    formatted_date: function() { return this.current_date.format('MMM Do YYYY'); },
    groups: []
  }

  //this.bind_handlers( [ this.prev_day, this.next_day ] );
  this.bind_handlers2();
  this.build_dom(parent);
  this.load_styles();
  this.bind_dom();
  this.set_formatted_date();
  this.get_occurrences();
}

Schedule.prototype = {

  constructor: Schedule,

  bind_handlers2() {
    this.prev_day = this.prev_day.bind(this);
    this.next_day = this.next_day.bind(this);
    this.get_occurrences = this.get_occurrences.bind(this);
  },

  prev_day() { this.state.current_date.subtract(7, 'days'); this.set_formatted_date(); this.get_occurrences(); },
  next_day() { this.state.current_date.add(7, 'days');      this.set_formatted_date(); this.get_occurrences();  },

  set_formatted_date() {
    this.state.formatted_date = this.state.current_date.format('ddd MMM Do YYYY');
    this.ev_fire( 'day_of_week', this.state.current_date.format('ddd') );
  },

  get_occurrences() {
    $.get(`/models/classdefs/schedule/${this.state.current_date.toISOString()}/${this.state.current_date.clone().add(7, 'days').toISOString()}`, function(occurrences) {
      this.state.groups = occurrences;
    }.bind(this), 'json');
  }

}

Object.assign( Schedule.prototype, element );
Object.assign( Schedule.prototype, ev_channel );

Schedule.prototype.HTML = `

  <div id='Schedule'>
    <div class='header'>
      <span rv-on-click='this.prev_day'> < </span>
      <div class='current_date'>
        Week Of { state.formatted_date }
      </div>
      <span rv-on-click='this.next_day'> > </span>
      <div class='daygroup' rv-each-group='state.groups' >
        <div class='dayname'>
          { group.day | dayofwk } { group.day | date }
        </div>
        <div class='occurrence' rv-each-occ='group.occurrences' >
          <span class='start'> { occ.starttime | unmilitary } </span> - 
          <span class='end'>   { occ.endtime | unmilitary } </span>
          <span class='classname'> { occ.title } </span>
          w/
          <span class='instructor' rv-each-inst='occ.instructors'> { inst.name } </span>
        </div>
      </div>
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

  #Schedule .daygroup {
    margin: 1em;
    padding: 1em;
  }

  #Schedule .start {
    display: inline-block;
  }

  #Schedule .classname {
    display: inline-block;
    width: 10em;
  }

  #Schedule .occurrence {
    background: rgba(255,255,255,0.1);
    margin: 1em;
    padding: 1em;
    vertical-align: middle;
  }

  #Schedule .occurrence span {
    vertical-align: middle;
  }

  #Schedule .instructor {
    width: 9em;
    display: inline-block
  }


`.untab(2);