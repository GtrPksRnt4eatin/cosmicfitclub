function DmxSliders(el) {
  this.state = {
    index: null,
    device: {
      capabilities: [],
      current_values: []
    }
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
  <table>
    <tr>
      <td rv-each-cap="this.state.device.capabilities">
        { cap }
      </td>
    </tr>
    <tr>
      <td rv-each-value="this.state.device.current_values">
        <input type="range" rv-value='value' rv-on-change='this.change_value'/>
      </td>
    </tr>
    <tr>
      <td rv-each-value="this.state.device.current_values">
       {cap.value}
      </td>
    </tr>
  </span>
`.untab(2);

DmxSliders.prototype.CSS = `

`.untab(2);