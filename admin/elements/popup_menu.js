function PopupMenu(parent) {

  this.state = {
    path: '',
      items: [],
      row_template: `<span>{item}</span>`,
      showing: false,
    position: 'top left',
    callback: null,
    content: null
  }
  
  this.bind_handlers( [ 'show' ] );
  this.parent = parent;
  this.build_dom();
  this.mount(parent,false);
  this.load_styles();
  this.bind_dom();
  this.set_close_listener();

}

PopupMenu.prototype = {
  constructor: PopupMenu,

  show(args) {
    if(this.state.content == args['dom']) { this.state.content=null; this.hide(); return; }
    this.state.position = args['position'];
    this.state.content = args['dom'] || this.state.content;
    if( empty( this.state.content ) ) return;
    this.dom.innerHTML = '';
    this.dom.appendChild(this.state.content);
    this.state.showing = true;
  },

  hide() { this.state.content=null; this.state.showing = false; },

  item_selected(e,m) {
    if(this.state.callback == null) return;
    if(this.state.close) this.hide();
    this.state.callback(e,m.index,m.item);
    cancelEvent(e);
  },

  set_close_listener() {
    document.onclick = function(e) {
      if( this.state.showing == false ) return;
      this.hide();
    }.bind(this);
  },

  set items(items)  { this.state.items = items;  },
  set position(pos) { this.state.position = pos; },
  set callback(cb)  { this.state.callback = cb;  },

  set row_template(template) {
    this.state.row_template = template;
    this.unbind_dom();
    this.build_dom();
    this.mount(this.parent);
    this.bind_dom();
  }
}

Object.assign( PopupMenu.prototype, element);

Object.defineProperty(PopupMenu.prototype, 'HTML', {
  get: function() { return `
    <div id='PopupMenu' rv-class='state.position' rv-if='state.showing'>
    </div>
  `.untab(4); }
});

PopupMenu.prototype.CSS = `

  #PopupMenu {
      font-size: 16pt;
      position: absolute;
      left: 0; right: 0;
      margin: auto;
      text-align: center;

    border: 1px solid rgba(0,0,0,0.6);
    max-width: 20%;
  }

  #PopupMenu.modal {
    top: 0; bottom: 0;
    background: rgba(0,0,0,0.3);
    border: none;
    max-width: none;
    box-shadow: none;
  }

  #PopupMenu.modal::before {
    display: inline-block;
    height: 90%;
    vertical-align: middle;
    content: '';
  }

  #PopupMenu.modal .menu {
    display: inline-block;
    background: #555;
    box-shadow: 0 .5em 1em rgba(0,0,0,0.2);
    border: 1px solid rgba(0,0,0,0.2);
    width: 20%;
    left: 0; right: 0;
    margin: auto;
    vertical-align: middle;
    border-radius: .5em;
  }

  #PopupMenu.modal .heading { display: block; }

  #PopupMenu.top {
    border-radius: 0 0 .5em .5em;
    top: 10vh;
  }

  #PopupMenu.top .list .item,
  #PopupMenu.modal .list .item,
  #PopupMenu.modal .heading {
      border-bottom: 1px solid #AAA;
  }

  #PopupMenu.top .list .item:last-child,
  #PopupMenu.modal .list .item:last-child {
      border-radius: 0 0 0.5em 0.5em;
      border-bottom: none;
  }

  #PopupMenu.bottom {
    border-radius: .5em .5em 0 0;
    bottom: 10vh;
  }

  #PopupMenu.left {
    right: auto;
  }

  #PopupMenu.right {
    left: auto;
  }

`.untab(2);