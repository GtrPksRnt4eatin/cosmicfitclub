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

jQuery.extend({
    put: function(url, data, callback, type) {
        return _ajax_request(url, data, callback, type, 'PUT');
    },
    del: function(url, data, callback, type) {
        return _ajax_request(url, data, callback, type, 'DELETE');
    }
});

function _ajax_request(url, data, callback, type, method) {
    if (jQuery.isFunction(data)) {
        callback = data;
        data = {};
    }
    return jQuery.ajax({
        type: method,
        url: url,
        data: data,
        success: callback,
        dataType: type
        });
}

function getUrlParameter(sParam) {
    var sPageURL = decodeURIComponent(window.location.search.substring(1)),
        sURLVariables = sPageURL.split('&'),
        sParameterName,
        i;

    for (i = 0; i < sURLVariables.length; i++) {
        sParameterName = sURLVariables[i].split('=');

        if (sParameterName[0] === sParam) {
            return sParameterName[1] === undefined ? true : sParameterName[1];
        }
    }
};

jQuery.fn.shake = function() {
  this.each(function(i){
    $(this).css({"position":"relative"});
    for(var i=1; i<=3; i++) {
      $(this).animate({left: -10}, 10).animate({left: 0}, 50).animate({left: 10}, 10).animate({left: 0}, 50);
    }
  });
  return this;
}

/////////////////////// Object.assign Polyfill for ES5 ///////////////////////////////

if (typeof Object.assign != 'function') {
  Object.assign = function(target, varArgs) { // .length of function is 2
    'use strict';
    if (target == null) { // TypeError if undefined or null
      throw new TypeError('Cannot convert undefined or null to object');
    }

    var to = Object(target);

    for (var index = 1; index < arguments.length; index++) {
      var nextSource = arguments[index];

      if (nextSource != null) { // Skip over if undefined or null
        for (var nextKey in nextSource) {
          // Avoid bugs when hasOwnProperty is shadowed
          if (Object.prototype.hasOwnProperty.call(nextSource, nextKey)) {
            to[nextKey] = nextSource[nextKey];
          }
        }
      }
    }
    return to;
  };
}

/////////////////////// Object.assign Polyfill for ES5 ///////////////////////////////