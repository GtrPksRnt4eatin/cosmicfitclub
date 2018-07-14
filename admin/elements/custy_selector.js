function CustySelector() {
  
  this.state = { 
    customers: [],
    selected_custy: null
  }

  this.bind_handlers([]);
  this.build_dom();
  this.load_styles();
  this.bind_dom();

}

CustySelector.prototype = {
  constructor: CustySelector
}

Object.assign( CustySelector.prototype, element);
Object.assign( CustySelector.prototype, ev_channel); 

ClassSelector.prototype.HTML =  ES5Template(function(){/**
  <div class='custy_selector'>
    
  </div>
**/}.untab(2);

ClassSelector.prototype.CSS = ES5Template(function(){/**
  .custy_selector {
	
  }

**/}.untab(2);