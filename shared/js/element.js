element = {
	build_dom(parent)  { this.dom = render(this.HTML); this.mount(parent);                           },
	load_styles()      { load_css(`${this.constructor.name}_styles`, this.CSS);                      },
    bind_dom()         { rivets.bind(this.dom, { state: this.state, this: this, global: this.constructor.state });                   },
    mount(parent)      { if(!empty(parent)) { parent.innerHTML = ''; parent.appendChild(this.dom); } },
    bind_handlers(arr) {
        if(empty(arr)) return;
    	for( var i=0; i < arr.length; i++ ) {
            if(this[arr[i]]) { this[arr[i]] = this[arr[i]].bind(this); }
            else { console.log("No Handler Named [" + arr[i] + "] Exists!"; } 
    	}         
    }
}
