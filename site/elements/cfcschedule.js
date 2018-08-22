function Schedule(parent) {
  
  this.state = {
  	current_date: moment().startOf('day'),
    formatted_date: function() { return this.current_date.format('MMM Do YYYY'); },
    groups: []
  }

  rivets.formatters.equals = function(val,arg) { return(val == arg); }
  
  rivets.formatters.show_classitem = function(val) { 
    if( val.type != 'classoccurrence' ) return false;
    if( val.exception && val.exception.hidden ) return false;
    return true;
  }

  rivets.formatters.class_cancelled = function(val) {
    if( val.type != 'classoccurrence' ) return false;
    if( empty( val.exception ) ) return false;
    if( val.exception.cancelled ) return true;
    return false;
  }
  
  rivets.formatters.event_title = function(val) {
    title = val.multisession_event ? val.event_title + '\r\n' + val.title : val.event_title;
    return title;
  }
  
  rivets.formatters.instructor_names = function(val) {
    if( val.type != 'classoccurrence' ) return false;
    if( !val.exception || !val.exception.teacher_id ) { 
      return val.instructors.map( function(val){ 
        return val ? val.name : null; 
      }).join(', '); 
    }
    return val.exception.teacher_name;
  },
  
  rivets.formatters.sub = function(val) {
    if( val.type != 'classoccurrence' ) return false;
    if( !val.exception ) return false;
    if( !val.exception.teacher_id ) return false
    return true;
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
    </div>

    <div class='daygroup' rv-each-group='state.groups' >
      <div class='dayname'>
        { group.day | dayofwk } { group.day | date }
      </div>

      <div class='occurrence' rv-each-occ='group.occurrences' >

        <div class='classitem' rv-if="occ | show_classitem" rv-data-cancelled='occ | class_cancelled' >
          <span class='classtime'>
            <span class='start'> { occ.starttime | unmilitary } </span> - 
            <span class='end'>   { occ.endtime | unmilitary } </span>
          </span>
          <span class='classdetail'>
            <span class='classname'> { occ.title } </span>
            <span> w/ </span>
            <span class='instructors' rv-data-sub='occ | sub'>
              <span class='instructor'> { occ | instructor_names } </span>
            </span>
          </span>
          <span class='register' rv-on-click='this.register' >
            { occ.headcount } / { occ.capacity } <br> <span class='blue'>Register Now</span>
          </span>
        </div>

        <div class='eventsession' rv-if="occ.type | equals 'eventsession'" rv-on-click='this.event_register'>
          <span class='start'> { occ.starttime | unmilitary } </span> - 
          <span class='end'>   { occ.endtime | unmilitary } </span>
          <span class='eventtitle'> { occ | event_title } </span>
        </div>

        <div class='rental' rv-if="occ.type | equals 'private'">
          <span class='start'> { occ.starttime | unmilitary } </span> - 
          <span class='end'>   { occ.endtime | unmilitary } </span>
          <span class='eventtitle'> Private Event: { occ.title } </span>
        </div>
 
      </div>
    </div>
  </div>

`.untab(2);

Schedule.prototype.CSS = `

  #Schedule .current_date {
    display: inline-block;
  }

  #Schedule .header {
    margin-top: 1em;
    font-size: 1.3em;
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
    width: 15em;
    padding: 0 1em;
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
  #Schedule .eventsession,
  #Schedule .rental {
    padding: 0.5em;
  }

  #Schedule .eventsession {
    background: rgba(255,255,0,0.2);
  }

  #Schedule .rental {
    background: rgba(0,0,255,0.2);
  }

  #Schedule .eventtitle {
    width: 34em;
    text-overflow: ellipsis;
    display: inline-block;
    white-space: pre-line;
    margin: 0 1em;
  }

  #Schedule .instructors {
    width: 9em;
    display: inline-block;
    text-overflow: ellipsis;
    margin: 0 1em;
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
    font-size: .8em;
    line-height: 1.5em;
  }

  #Schedule .instructors[data-sub=true] {
    color: rgb(255,230,150);
    font-style: italic;
  }

  #Schedule .classitem[data-cancelled=true] span span {
    text-decoration: line-through solid red;
  }

  #Schedule .classitem[data-cancelled=true] .register {
    visibility: hidden;
  }

  @media(max-width: 1130px) {
  
    #Schedule .occurrence {
      font-size: 1.8vw;
    }

  }

`.untab(2);