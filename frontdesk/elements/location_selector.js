function LocationSelector(el, attr, build_dom) {

  this.dom  = el;
  this.attr = attr;

  this.state = {
    "locations": []
  }

  this.load_styles();
  this.bind_handlers(['show','get_locations','select']);
  this.get_staff();
  
  if(this.dom == null) {
    this.build_dom();
    this.bind_dom();
  }

}

LocationSelector.prototype = {
  constructor: LocationSelector,

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
    $.get('/models/location', null, null, 'json')
     .success( function(resp) { this.state['locations'] = resp; }.bind(this) );
  }
}

Object.assign( LocationSelector.prototype, element );
Object.assign( LocationSelector.prototype, ev_channel );

LocationSelector.prototype.HTML = ES5Template(function(){ /**

  <div class='location_selector'>
    <div class='title'>Choose A Location</div>
    <div>
      <select rv-on-change='this.select'>
        <option rv-each-loc='state.locations' rv-value='loc.id'>
          { loc.name }
        </option>
      </select>
    </div>
  </div>

**/}).untab(2);

LocationSelector.prototype.CSS = ES5Template(function(){ /**

  .location_selector {
    display: inline-block;
    vertical-align: middle;
    background: rgb(60,60,60);
    padding: 1.2em;
    border-radius: 1em;
    box-shadow: 0em 0em 2em white;
  }

  .location_selector .title {
    font-size: 1.2em;
    padding: 0.5em;
  }

**/}).untab(2);

//rivets.components['teacher_selector'] = {
//  template:   function()        { return LocationSelector.prototype.HTML },
//  initialize: function(el,attr) { return new LocationSelector(el,attr); }
//}