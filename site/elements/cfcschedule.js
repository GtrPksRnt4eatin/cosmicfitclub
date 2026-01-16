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

  rivets.formatters.past = function(val) {
    return moment(val).isBefore(moment());
  }
  
  rivets.formatters.instructor_names = function(val) {
    if( val.type != 'classoccurrence' ) return false;
    if( !val.exception || !val.exception.changes.sub ) { 
      return val.instructors.map( function(val){ 
        return val ? val.name : null; 
      }).join(', '); 
    }
    return val.exception.changes.sub.name;
  },
  
  rivets.formatters.sub = function(val) {
    if( val.type != 'classoccurrence' ) return false;
    if( !val.exception ) return false;
    if( !val.exception.changes.sub ) return false;
    return true;
  },

  rivets.formatters.slots_remaining = function(val) {
    if( val.type != 'classoccurrence' )          return false;
    if( moment(val.endtime).isBefore(moment()) ) return false;
    //if(val.location.id == 3) { return "Video Class"; }
    var remaining = val.capacity - val.headcount
    if( remaining <= 0 )  return false;
    if( remaining >= 10 ) return "Register Now";
    if( remaining == 1 )  return "1 Spot Left";
    return ( remaining + " Spots Left" )
  },

  rivets.formatters.allow_reg = function(val) {
    if( val.type != 'classoccurrence' )          return false;
    if( moment(val.endtime).isBefore(moment()) ) return false;  
    return ( val.capacity - val.headcount > 0 )
  },

  rivets.formatters.class_full = function(val) {
    if( moment(val.endtime).isBefore(moment()) ) return false;
    return ( val.capacity - val.headcount == 0 )
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
    this.details = this.details.bind(this);
    this.event_register = this.event_register.bind(this);
  },

  prev_day() { this.state.current_date.subtract(7, 'days'); this.set_formatted_date(); this.get_occurrences(); },
  next_day() { this.state.current_date.add(7, 'days');      this.set_formatted_date(); this.get_occurrences();  },

  set_formatted_date() {
    this.state.formatted_date = this.state.current_date.format('ddd MMM Do YYYY');
    this.ev_fire( 'day_of_week', this.state.current_date.format('ddd') );
  },

  get_occurrences() {
    this.dom.setAttribute('data-loading', true);
    $.get(`/models/schedule/${this.state.current_date.toISOString()}/${this.state.current_date.clone().add(7, 'days').toISOString()}`, function(occurrences) {
      occurrences.forEach( function(x) { 
        x.occurrences = x.occurrences.filter( function(y) { 
          return ![173,188].includes(y.classdef_id); 
        }); 
      });
      this.state.groups = occurrences;
      this.dom.setAttribute('data-loading', false);
    }.bind(this), 'json');
  },

  register(e,m) {
    if(m.occ.location.id == 3) { window.location = "https://video.cosmicfitclub.com"; }
    else {
      $.post(`/models/classdefs/occurrences`, { "classdef_id": m.occ.classdef.id, "staff_id": m.occ.instructors[0].id, "starttime": m.occ.starttime, "location_id": m.occ.location.id }, 'json')
       .fail(    function(req,msg,status) { alert('failed to get occurrence');                    } )
       .success( function(data)           { window.location = `https://cosmicfitclub.com/checkout/class_reg/${data['id']}` } ); 
    }
  },

  details(e,m) {
    window.location = '/classes/details/' + m.occ.classdef.id;
  },

  event_register(e,m) {
    window.location = '/checkout/event/' + m.occ.event_id;
  }

}

Object.assign( Schedule.prototype, element );
Object.assign( Schedule.prototype, ev_channel );

Schedule.prototype.HTML = `

  <div id='Schedule' data-loading='false' >
    <div class='header'>
      <div class='current_date'>
        Week Of { state.formatted_date }
      </div>
      <span class='prev' rv-on-click='this.prev_day'> < prev week </span>
      <span class='next' rv-on-click='this.next_day'> next week > </span>
    </div>

    <div class='daygroup' rv-each-group='state.groups' >
      <div class='dayname'>
        { group.day | dayofwk } { group.day | date }
      </div>

      <div class='occurrence' rv-each-occ='group.occurrences' >

        <div class='classitem' rv-if="occ | show_classitem" rv-data-cancelled='occ | class_cancelled' >
          <img rv-src='occ.thumb_url'/>
          <div class='classinfo' rv-on-click='this.details'>
            <span class='classtime'>
              <span class='start'> { occ.starttime | unmilitary } </span> - 
              <span class='end'>   { occ.endtime | unmilitary } </span>
            </span>
            <span class='classname'> { occ.title } </span>
            <span class='instructors' rv-data-sub='occ | sub'>
              <span class='instructor'>w/ { occ | instructor_names } </span>
            </span>
            <span class='location'>
              @ { occ.location.name }
            </span>
            <span class='register'>
              <span class='blue' rv-if='occ | allow_reg' rv-on-click='this.register'> { occ | slots_remaining } </span>
              <span class='red'  rv-if='occ | class_full'> Class Is Full </span>
            </span>
          </div>
        </div>

        <div class='eventsession' rv-if="occ.type | equals 'eventsession'" rv-on-click='this.event_register'>
          <img rv-src='occ.thumb_url'/>
          <div class='classinfo'>
            <span class='classtime'>
              <span class='start'> { occ.starttime | unmilitary } </span> - 
              <span class='end'>   { occ.endtime | unmilitary } </span>
            </span>
            <span class='eventtitle'> { occ | event_title } </span>
          </div>
        </div>
        
        <div class='rental' rv-if="occ.type | equals 'private'">
          <img rv-src='occ.thumb_url'/>
          <div class='classinfo'>
            <span class='classtime'>
              <span class='start'> { occ.starttime | unmilitary } </span> - 
              <span class='end'>   { occ.endtime | unmilitary } </span>
            </span>
            <span class='eventtitle'> Private Event: { occ.title } </span>
          </div>
        </div>
 
      </div>
    </div>

    <div class='header'>
      <div class='current_date'>
        Week Of { state.formatted_date }
      </div>
      <span class='prev' rv-on-click='this.prev_day'> < prev week </span>
      <span class='next' rv-on-click='this.next_day'> next week > </span>
    </div>

  </div>

`.untab(2);

Schedule.prototype.CSS = `

  #Schedule {
    letter-spacing: 0.04em;
    padding-bottom: 1em;
  }

  #Schedule .header {
    margin-top: 1em;
    font-size: 1.2em;
  }

  #Schedule .footer {
    margin-bottom: 1em;
    font-size: 1.2em
  }

  #Schedule .header span,
  #Schedule .footer span {
    display: inline-block;
    cursor: pointer;
    padding: 0 1em;
    background: rgba(255,255,255,0.1);
  }

  #Schedule .header span:hover,
  #Schedule .footer span:hover {
    background: rgba(255,255,255,0.2);
  }

  #Schedule span.prev { padding: 0.1em 2em 0.2em 0.2em; margin: 0.5em 1em 0 0; }   
  #Schedule span.next { padding: 0.1em 0.2em 0.2em 2em; margin: 0.5em 0 0 1em; }

  #Schedule .daygroup {
    margin: 0.5em;
    padding: 0.5em;
    position: relative;
  }

  #Schedule['data-loading'=true] .daygroup:before {
    content: '';
    background: rgba(0,0,0,0.6);
    top: 0;
    right: 0;
    left: 0;
    bottom: 0;
    display: inline-block;
    position: absolute;
  }

  #Schedule .classtime .start,
  #Schedule .classtime .end {
    display: inline-block;
    padding: 0;
  }

  #Schedule .classname {
    display: inline-block;
  }

  #Schedule .occurrence {
    background: rgba(255,255,255,0.1);
    margin: 0.25em;
    vertical-align: middle;
    line-height: 1.3em;
  }
  
  #Schedule .occurrence img {
    border-radius: 0.5em;
    width: 5em;
    height: 5em;
    box-shadow: 0 0 0.5em rgb(180,180,180);
    vertical-align: middle;
    margin: 0.3em;
  }

  #Schedule .occurrence span {
    vertical-align: middle;
  }

  #Schedule .classitem,
  #Schedule .eventsession,
  #Schedule .rental {
    padding: 0.5em;
    display: flex;
  }

  #Schedule .eventsession {
    background: rgba(255,255,0,0.2);
  }

  #Schedule .rental {
    background: rgba(0,0,255,0.2);
  }
  
  #Schedule .classinfo {
    display: flex;
    flex-direction: column;
    margin-left: 2em;
    text-align: left;
  }

  #Schedule .eventtitle {
    width: 34em;
    text-overflow: ellipsis;
    display: inline-block;
    white-space: pre-line;
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

  #Schedule .location {
    padding-right: 1em;
  }

  #Schedule .register .blue {
    cursor: pointer;
  }

  #Schedule .blue {
    color: rgba(150,150,255,0.9);
  }

  #Schedule .red {
    color: rgba(255,100,100,0.9);
  }

  #Schedule .register {
    display: inline-block;
    font-size: 1em;
    line-height: 1.5em;
    position: absolute;
    right: 2em;
  }

  #Schedule .register span {
    display: block;
  }

  #Schedule .register span.headcount {
    color: rgba(150,150,255,0.9);
    font-size: 0.5em;
  }

  #Schedule .instructors[data-sub=true] {
    color: rgb(255,230,150);
    font-style: italic;
  }

  #Schedule .classitem[data-cancelled=true] span {
    position: relative;
    display: inline-block;
  }

  #Schedule .classitem[data-cancelled=true] span::before {
    content: '';
    border-bottom: 4px solid red;
    width: 100%;
    position: absolute;
    right: 0;
    top: 50%;
  }

  #Schedule .classitem[data-cancelled=true] .register {
    visibility: hidden;
  }

  @media(max-width: 1200px) {
  
    #Schedule .occurrence {
      font-size: 2.5vw;
      line-height: 1.5em;
      position: relative;
    }

    #Schedule .occurrence span {
      display: block;
    }

    #Schedule .register span,
    #Schedule .eventsession .start,
    #Schedule .eventsession .end {
      display: inline-block;
    }

    #Schedule .eventtitle,
    #Schedule .classname,
    #Schedule .instructors {
      width: auto;
    }
        
    #Schedule .classname,
    #Schedule .instructors {
      padding: 0 0.25em;
    }

    #Schedule .instructors {
      vertical-align: bottom;
      margin: 0;
    }

    #Schedule .register br {
      display: none;
    }

  }

`.untab(2);
