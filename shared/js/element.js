element = {
	build_dom(parent)  { this.dom = render(this.HTML); this.mount(parent);                           },
	load_styles()      { load_css(`${this.constructor.name}_styles`, this.CSS);                      },
    bind_dom()         { rivets.bind(this.dom, { state: this.state, this: this });                   },
    mount(parent)      { if(!empty(parent)) { parent.innerHTML = ''; parent.appendChild(this.dom); } },
    bind_handlers(arr) { 
    	for( var i=0; i < arr.length; i++ ) { 
    		arr[i] = arr[i].bind(this); 
    	}         
    }
}