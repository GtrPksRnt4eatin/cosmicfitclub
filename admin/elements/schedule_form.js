function ScheduleForm() {

  this.state = {
  	"schedule": {},
    "instructors": []
  }

  this.bind_handlers(['save']);
  this.build_dom();
  this.load_styles();

  $(this.dom).find('#starttime').on('change', function(e) {
    if( moment(this.state.schedule.start_time,['H:m:s','H:m']) > moment(this.state.schedule.end_time,['H:m:s','H:m'])) {
      this.state.schedule.end_time = moment(this.state.schedule.start_time,['H:m:s','H:m']).format('H:m:s');
    }
  }.bind(this));

}

ScheduleForm.prototype = {

  constructor: ScheduleForm,

  show_new()  { 
  	this.state.schedule = { "id": 0 };
  	this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} ); 
  },

  show_edit(sched) { 
  	this.state.schedule = sched;
  	this.ev_fire('show', { 'dom': this.dom, 'position': 'modal'} ); 
  },

  save(e) {
    $.post(`/models/classdefs/${data['class'].id}/schedules`, JSON.stringify(this.state.schedule), function(sched) {
      this.ev_fire('after_post', sched );
    }.bind(this));  
  },

  set instructors(val) { this.state.instructors = val;   this.bind_dom(); }

}


Object.assign( ScheduleForm.prototype, element);
Object.assign( ScheduleForm.prototype, ev_channel); 

ScheduleForm.prototype.HTML = `
  
  <div class='scheduleform form'>
    <div class='tuplet'>
      <label>Instructors:</label>
      <select multiple='multiple' rv-multiselect='state.schedule.instructors'>
        <option rv-each-inst='state.instructors' rv-value='inst.id'> { inst.name } </option>
      </select>
    </div>
    <div class='tuplet'>
      <label>Weekday:</label>
      <select rv-value='state.schedule.rrule'>
        <option value='FREQ=WEEKLY;BYDAY=MO;INTERVAL=1' >Mondays</option>
        <option value='FREQ=WEEKLY;BYDAY=TU;INTERVAL=1' >Tuesdays</option>
        <option value='FREQ=WEEKLY;BYDAY=WE;INTERVAL=1' >Wednesdays</option>
        <option value='FREQ=WEEKLY;BYDAY=TH;INTERVAL=1' >Thursdays</option>
        <option value='FREQ=WEEKLY;BYDAY=FR;INTERVAL=1' >Fridays</option>
        <option value='FREQ=WEEKLY;BYDAY=SA;INTERVAL=1' >Saturdays</option>
        <option value='FREQ=WEEKLY;BYDAY=SU;INTERVAL=1' >Sundays</option>
      </select>
    </div>
    <div class='tuplet'>
      <label>Start Time:</label>
      <input id='starttime' class='time' rv-timefield='state.schedule.start_time' />
    </div>
    <div class='tuplet'>
      <label>End Time:</label>
      <input id='endtime' class='time' rv-timefield='state.schedule.end_time' />
    </div>
    <div class='done' rv-on-click='this.save'>Save</div>
  </div>

`.untab(2);

ScheduleForm.prototype.CSS = `

  .scheduleform {
    
  }

  .scheduleform input,
  .scheduleform textarea {
    font-size: 1em !important;
    width: 20em;
  }

  .scheduleform .done {
    cursor: pointer;
  }

  .sesionform textarea {
    width: 20em;
    background: white;
  }

  .scheduleform select {
  	font-size: inherit;
  	font-family: inherit;
  	width: 20em;
  	padding: .2em;
  }

  .scheduleform .flatpickr-time input {
    width: 4em !important;
  }

  .scheduleform .form-control {
    display: none !important;
  }

  .scheduleform .flatpickr-calendar.noCalendar {
    display: inline-block;
    font-size: inherit;
    width: 20em;
  }

  .scheduleform .flatpickr-calendar.arrowTop:before,
  .scheduleform .flatpickr-calendar.arrowTop:after {
    display: none !important;
  }

  .scheduleform .chosen-container {
    width: 20em !important;
    font-size: 1em; 
  }

  .scheduleform .done {
    margin-top: 1em;
    padding: .5em;
    cursor: pointer;
    background: rgba(255,255,255,0.2);
  }

`.untab(2);
