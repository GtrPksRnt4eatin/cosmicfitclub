function DmxSliders(el) {
  this.state = {
    index: null,
    device: {
      capabilities: [],
      current_values: []
    }
  }

  this.build_dom();
  this.bind_dom();
  this.bind_handlers(['load_device', 'show', 'change_value'])
  this.load_styles();
}

DmxSliders.prototype = {
  constructor: DmxSliders,

  load_device(index) {
    this.state.index = index;
    $.get(`/dmx/device/${index}`, function(resp) {
      this.state.device.capabilities = resp.capabilities;
      this.state.device.current_values = resp.current_values;
    }.bind(this), 'json');
  },

  show: function() {
    this.ev_fire('show', { 'dom': this.dom, 'position': 'modal' });
  },

  change_value(e,m) {
    let val = e.target.value;
    let cap = this.state.device.capabilities[m.index];
    $.post('/dmx/cmd', { index: this.state.index, capability: cap, value: val });
  }

}

Object.assign( DmxSliders.prototype, element );
Object.assign( DmxSliders.prototype, ev_channel );

DmxSliders.prototype.HTML = `
  <table id="dmx_sliders">
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

  #dmx_sliders input {
    writing-mode: vertical-lr;
    direction: rtl;
  }

  #dmx_sliders {
    font-size: 8pt;
  }
`.untab(2);