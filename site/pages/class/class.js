data = {
  class: {},
  sessions: []
}

ctrl = {
 
  register: function(e,m) {
    $.post(`/models/classdefs/occurrences`, { "classdef_id": data.class.id, "staff_id": m.occ.teachers[0].id, "starttime": m.occ.starttime }, 'json')
     .fail(    function(req,msg,status) { alert('failed to get occurrence');                    } )
     .success( function(data)           { window.location = "/checkout/class_reg/" + data['id'] } ); 
  } 

}

$(document).ready(function() {

  include_rivets_dates();

  rivets.formatters.no_parens = function(val) {
    if( empty(val) ) return null;
  	return val.replace(/ ?\(.*\)/,'');
  }
   
  rivets.formatters.list = function(val,param) {
  	if( val.length == 1 ) return val[0][param];
  	if( val.length == 2 ) return val[0][param] + " & " + val[1][param];
  	if( val.length == 3 ) return val[0][param] + ", " + val[1][param] + " & " + val[2][param];
  }

  rivets.binders['bgimg'] = function(el, value){ el.style.setProperty("background", "url('" + value + "')" ); };

  rivets.bind( document.body, { data: data, ctrl: ctrl })

  get_class();
  get_occurrences();

})

function get_class() {
  $.get('/models/classdefs/' + CLASSDEF_ID )
   .success( function(resp) { data.class = resp; } )
   .fail( function() { alert("Couldn't Get Class"); } )
}

function get_occurrences() {
  $.get('/models/classdefs/' + CLASSDEF_ID + '/next_occurrences/5')
   .success( function(resp) { data.sessions = resp; } )
   .fail( function() { alert("Couldn't Get Sessions!"); } )
}