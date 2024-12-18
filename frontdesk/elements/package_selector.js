function PackageSelector(el, attr, build_dom) {
  this.dom = el;
  this.attr = attr;
  this.state = {
    packages: []
  };

  this.get_packages();
  this.bind_handlers(['select', 'get_packages']);
}

PackageSelector.prototype = {
  constructor: PackageSelector,

  select: function(e,m) {
    //let pack = m.state.packages.find( function(x) { return x.id == parseInt(e.target.value)} );
    this.attr['onSelect'] && this.attr['onSelect'].call(m.pack);
    this.ev_fire('select', e.target.value);
  },

  get_packages: function() {
    $.get("/models/passes/packages/front_desk", null, null, 'json')
     .success( function(resp) { this.state['packages'] = resp; }.bind(this) );
  }
}

Object.assign( PackageSelector.prototype, element );
Object.assign( PackageSelector.prototype, ev_channel );

PackageSelector.prototype.HTML = `
  <div>
    <div class='title'>Choose A Package</div>
    <div>
      <select>
        <option value='0' data-price='0'> None </option>
        <option rv-each-pack="state.packages" rv-on-click='select' rv-value='pack.id'>
          { pack.formatted_price } { pack.name }
        </option>
      </select>
    </div>
  </div>
`.untab(2);

PackageSelector.prototype.CSS = `

`.untab(2);

rivets.components['package-selector'] = {
  template:   function()        { return PackageSelector.prototype.HTML },
  initialize: function(el,attr) { return new PackageSelector(el,attr);  }
}
