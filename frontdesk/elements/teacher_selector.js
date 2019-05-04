function TeacherSelector(el, attr, build_dom) {

  this.dom  = el;
  this.attr = attr;

  this.state = {
    "staff_list": []
  }

  this.load_styles();
  this.bind_handlers(['show','get_staff','select']);
  this.get_staff();
  
  if(this.dom == null) {
    this.build_dom();
    this.bind_dom();
  }

}

TeacherSelector.prototype = {
  constructor: TeacherSelector,

  show: function() {
    this.ev_fire('show', this.dom);
  },

  hide: function() {
    this.ev_fire('hide');
  },

  select: function(e,m) {
    this.hide();
    this.ev_fire('select', e.target.value);
  },

  get_staff: function() {
    $.get('/models/staff', null, null, 'json')
     .success( function(resp) { this.state['staff_list'] = resp; }.bind(this) );
  }
}

Object.assign( TeacherSelector.prototype, element );
Object.assign( TeacherSelector.prototype, ev_channel );

TeacherSelector.prototype.HTML = ES5Template(function(){ /**

  <div class='teacher_selector'>
    <div class='title'>Choose A New Class Teacher</div>
    <div>
      <select rv-on-change='this.select'>
        <option rv-each-staff='state.staff_list' rv-value='staff.id'>
          { staff.name }
        </option>
      </select>
    </div>
  </div>

**/}).untab(2);

TeacherSelector.prototype.CSS = ES5Template(function(){ /**

  .teacher_selector {
    display: inline-block;
    vertical-align: middle;
    background: rgb(60,60,60);
    padding: 1.2em;
    border-radius: 1em;
    box-shadow: 0em 0em 2em white;
  }

  .teacher_selector .title {
    font-size: 1.2em;
    padding: 0.5em;
  }

**/}).untab(2);

//rivets.components['teacher_selector'] = {
//  template:   function()        { return TeacherSelector.prototype.HTML },
//  initialize: function(el,attr) { return new TeacherSelector(el,attr); }
//}