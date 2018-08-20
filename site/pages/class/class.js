ctrl = {
 
  register: function(e,m) {
    $.post(`/models/classdefs/occurrences`, { "classdef_id": data.class.classdef_id, "staff_id": m.occ.teachers[0].id, "starttime": m.occ.starttime }, 'json')
     .fail(    function(req,msg,status) { alert('failed to get occurrence');                    } )
     .success( function(data)           { window.location = "/checkout/class_reg/" + data['id'] } ); 
  } 

}

$(document).ready(function() {

  include_rivets_dates();
   
  rivets.formatters.list = function(val) {
  	if( val.length == 1 ) return val[0];
  	if( val.length == 2 ) return val[0] + " & " + val[1];
  	if( val.length == 3 ) return val[0] + ", " + val[1] + " & " + val[2];
  }

  rivets.binders['bgimg'] = function(el, value){ el.style.setProperty("background", "url('" + value + "')" ); };

  rivets.bind( document.body, { data: data, ctrl: ctrl })

})