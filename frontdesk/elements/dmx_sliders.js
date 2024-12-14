function DmxSliders(el) {
  this.state = {
    index: null,
    capabilities: [],
    values: []
  }

  this.dom = this.build_dom();
  this.load_styles();
}

DmxSliders.prototype = {
  constructor: DmxSliders,

  load_device(index) {
    this.state.index = index;
    $.get("/dmx/device/#{index}", function(resp) {
      this.state.capabilities = resp;
    }.bind(this), 'json');
  },

  show: function() {
    this.ev_fire(show, this.dom);
  },

  change_value(e,m) {
    let val = e.target.value;
    $.post('/dmx/cmd', { index: this.state.index, capability: m.cap.name, value: val });
  }

}

Object.assign( DmxSliders.prototype, element );
Object.assign( DmxSliders.prototype, ev_channel );

DmxSliders.prototype.HTML = `
  <span rv-each-cap="">
    <input type="range" rv-value='cap.name' rv-on-change='this.change_value'/>
    <span>{cap.value}</span>
  </span>
`.untab(2);

DmxSliders.prototype.CSS = `

`.untab(2);