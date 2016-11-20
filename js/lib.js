function make(tag, cls, parent) {
  var element = document.createElement(tag);
  element.className = cls;
  if(parent!=null) { parent.appendChild(element); }
  return element;
}

function id(tag) { return document.getElementById(tag); }

function cancelEvent(e) { e.stopPropagation(); e.cancelBubble = true; }

function isFunction(functionToCheck) {
 var getType = {};
 return functionToCheck && getType.toString.call(functionToCheck) === '[object Function]';
}

function render(html) {
  var elem = document.createElement('div');
  elem.innerHTML = html;
  if(elem.children.length==1) return elem.children[0];
  throw `Error Rendering HTML: ${html}`;
}


function load_css(id,css) {
  var elem = document.createElement('style');
  elem.id = id;
  elem.innerHTML = css;
  document.getElementsByTagName("head")[0].appendChild(elem);  
}

function SortByTime(a, b) { 
  return ((parseFloat(a.time) < parseFloat(b.time)) ? -1 : ((parseFloat(a.time) > parseFloat(b.time)) ? 1 : 0));
}

function empty(obj) {
  return( typeof(obj) == 'undefined' || obj == null );
}

function val_or_default(obj,def) {
  return( empty(obj) ? def : obj);  
}

function val_or_null(obj) {
  return val_or_default(obj,null);
}
  
function display_time(time_s, options = {}) {
  if( empty(time_s) ) return '';

  var hrs,mins,secs,ms;

  ms   = ( time_s * 1000 ).toFixed();
  hrs  = Math.floor( ms / 3600000 );
  ms   = ms - hrs * 3600000;
  mins = Math.floor( ms / 60000 );
  ms   = ms - mins * 60000;
  secs = Math.floor( ms / 1000 );
  ms   = ms - secs * 1000;

  hrs  =  hrs.toLocaleString('en-US', { minimumIntegerDigits: 2, useGrouping: false });
  mins = mins.toLocaleString('en-US', { minimumIntegerDigits: 2, useGrouping: false });
  secs = secs.toLocaleString('en-US', { minimumIntegerDigits: 2, useGrouping: false });
  ms   =   ms.toLocaleString('en-US', { minimumIntegerDigits: 3, useGrouping: false });
  
  if(val_or_default(options.tenths,   false)) { ms = ms.slice(0,1); }
  if(val_or_default(options.no_hours, false)) { hrs = null; }
  if(val_or_default(options.no_ms,    false)) { ms = null; }

  return ( hrs ? hrs + ':' : '' ) + mins + ':' + secs + ( ms ? '.' + ms : '' );
}
/*
Object.prototype._bind_handlers = function(arr_of_handlers) {
  for(var i; i<arr_of_handlers.length; i++) {
    this.arr_of_handlers[i] = this.arr_of_handlers[i].bind(this)
  } 
}
*/
Array.prototype.for_each = function foreach(arr, func) {
  for(var i=0; i<arr.length; i++) { func(arr[i]); }
}

String.prototype.untab = function(spacing) {
  var lines = this.split("\n");
  lines = lines.filter(function(el) { return el.length > spacing; } )
  lines = lines.map(function(el) { 
    return el.split('').splice(spacing,el.length-spacing).join('')
  });
  return lines.join('\n');  
}