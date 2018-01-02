function Schedule(parent) {
  
  this.state = {
  	current_date: moment().startOf('day'),
    formatted_date: function() { return this.current_date.format('MMM Do YYYY'); },
    groups: []
  }

  rivets.formatters.equals = function(val,arg) { 
    return(val == arg); 
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
    this.register = this.register.bind(this);
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
    $.get(`/models/schedule/${this.state.current_date.toISOString()}/${this.state.current_date.clone().add(7, 'days').toISOString()}`, function(occurrences) {
      this.state.groups = occurrences;
    }.bind(this), 'json');
  },

  register(e,m) {
    $.post(`/models/classdefs/occurrences`, { "classdef_id": m.occ.classdef_id, "staff_id": m.occ.instructors[0].id, "starttime": m.occ.starttime }, 'json')
     .fail(    function(req,msg,status) { alert('failed to get occurrence');                    } )
     .success( function(data)           { window.location = `https://cosmicfitclub.com/checkout/class_reg/${data['id']}` } ); 
  },

  event_register(e,m) {
    window.location = '/checkout/event/' + m.occ.event_id;
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

          <div class='classitem' rv-if="occ.type | equals 'classoccurrence'">
            <span class='start'> { occ.starttime | unmilitary } </span> - 
            <span class='end'>   { occ.endtime | unmilitary } </span>
            <span class='classname'> { occ.title } </span>
            w/
            <span class='instructors'>
              <span class='instructor' rv-each-inst='occ.instructors'> { inst.name } </span>
            </span>
            <span class='register' rv-on-click='this.register' >
              { occ.headcount } / { occ.capacity } <br> <span class='blue'>Register Now</span>
            </span>
          </div>

          <div class='eventsession' rv-if="occ.type | equals 'eventsession'"" rv-on-click='this.event_register'>
            <span class='start'> { occ.starttime | unmilitary } </span> - 
            <span class='end'>   { occ.endtime | unmilitary } </span>
            <span> Event: { occ.title } </span>
          </div> 
 
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
    margin: 0.5em;
    padding: 0.5em;
  }

  #Schedule .start,
  #Schecule .end {
    display: inline-block;
    padding: 0;
  }

  #Schedule .classname {
    display: inline-block;
    width: 10em;
  }

  #Schedule .occurrence {
    background: rgba(255,255,255,0.1);
    margin: 0.25em;
    vertical-align: middle;
    line-height: 1.3em;
  }

  #Schedule .occurrence span {
    vertical-align: middle;
  }

  #Schedule .classitem,
  #Schedule .eventsession {
    padding: 0.5em;
  }

  #Schedule .eventsession {
    background: rgba(255,255,0,0.2);
  }

  #Schedule .instructors {
    width: 9em;
    display: inline-block;
    text-overflow: ellipsis;
  }

  #Schedule .instructor {
    padding: 0;
    display: inline-block
  }

  #Schedule .blue {
    color: rgba(150,150,255,0.9);
  }

  #Schedule .register {
    display: inline-block;
    font-size: .5em;
    line-height: 2em;
  }

  @media(max-width: 1100px) {
  
    #Schedule .occurrence {
      font-size: 1.8vw;
    }

  }

`.untab(2);