function PopupMenu(parent) {

  this.state = {
    showing: false,
    position: 'top left',
    content: null
  }
  
  this.bind_handlers( [ 'show', 'hide' ] );
  this.parent = parent;
  this.build_dom();
  this.mount(parent,false);
  this.load_styles();
  //this.bind_dom();
  this.set_close_listener();

}

PopupMenu.prototype = {
  constructor: PopupMenu,

  show(args) {
    if(this.state.content == args['dom']) { this.state.content=null; this.hide(); return; }
    this.dom.className = args['position'];
    this.state.content = args['dom'] || this.state.content;
    if( empty( this.state.content ) ) return;
    this.dom.innerHTML = '';
    this.dom.appendChild(this.state.content);
    this.state.showing = true;
    $(this.dom).show();
  },

  hide() { this.state.showing = false; this.state.content=null; $(this.dom).hide(); },

  set_close_listener() {
    this.dom.onclick = function(e) { 
      if( e.target.id=='PopupMenu' ) this.hide(); 
    }.bind(this);
  }

}

Object.assign( PopupMenu.prototype, element);

PopupMenu.prototype.HTML = `
  <div id='PopupMenu'></div>
`.untab(2);


PopupMenu.prototype.CSS = `

  #PopupMenu {
    font-size: 16pt;
    position: fixed;
    left: 0; right: 0;
    margin: auto;
    text-align: center; 
    border: 1px solid rgba(0,0,0,0.6);
    max-width: 20%;
  }

  #PopupMenu.modal {
    top: 0; bottom: 0;
    background: rgba(0,0,0,0.5);
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

  #PopupMenu.modal .form {
    display: inline-block;
    left: 0; right: 0;
    margin: auto;
    vertical-align: middle;
    background: rgb(100,100,100);
    padding: 1em;
    box-shadow: 0 0 0.5em white; 
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