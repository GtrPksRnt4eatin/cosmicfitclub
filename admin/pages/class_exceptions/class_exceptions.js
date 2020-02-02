data = {
  classdefs: [],
  selected_classdef: null,
  scheditems: [],
  selected_scheditem: null,
  exception: {
  	classdef_id: null,
  	original_starttime: null,
  	starttime: null,
    endtime: null,
  	teacher_id: null,
  	hidden: false,
  	cancelled: false,
    duration: null
  },
  hours: [1,1.5,2,2.5,3,3.5,4,4.5,5,5.5,6,6.5,7,7.5,8]
};

ctrl = {
  
  class_selected(e,m) {
  	data.selected_scheditem = null;
  	var option = e.target.children[e.target.selectedIndex]
  	data.selected_classdef = { id: option.value, name: option.innerText };
  	data.exception.classdef_id = option.value;
  	get_scheditems();
  },

  date_selected(e,m) {
    if( e.target.value == "" ) return; 
    get_scheditems_bydate(data.search_date);
  },

  scheditem_selected(e,m) {
  	data.selected_scheditem = Object.assign({}, m.scheditem);
  	if(data.selected_scheditem.exception) { data.exception = data.selected_scheditem.exception; return; }
  	data.exception = {
  	  id: 0,
  	  classdef_id: data.selected_classdef.id,
  	  original_starttime: m.scheditem.starttime,
  	  starttime: m.scheditem.starttime,
  	  teacher_id: 0,
  	  hidden: false,
  	  cancelled: false,
      endtime: m.scheditem.endtime
    }
  },

  post_exception(e,m) {
    if( e.target.value == "" ) return;
    setTimeout( function(){
      $.post('/models/classdefs/exceptions', data.exception)
       .done(  function(val) { setTimeout(get_scheditems,200); } )
       .error( function(xhr) { alert(xhr.responseText); } )
    }, 100); 
  },

  remove_exception(e,m) {
    $.del('/models/classdefs/exceptions/' + data.exception.id )
     .done(  function(val) { setTimeout(get_scheditems,200); } )
     .error( function(xhr) { alert(xhr.responseText); } )
  }
}

$(document).ready(function() { 
	include_rivets_dates();
	include_rivets_select();
	rivets.formatters['exception_classes'] = function(val) { 
		if(empty(val)) return '';
		return `${val.hidden ? 'hidden' : ''  } ${val.cancelled ? 'cancelled' : '' }`; 
	}
	rivets.bind( document.body, { data: data, ctrl: ctrl } );
});

function get_scheditems() {
  $.get('/models/classdefs/' + data.selected_classdef.id + '/schedule')
   .done(  function(val) { data.scheditems = val;  } )
   .error( function(xhr) { alert(xhr.responseText); } )
}

function get_scheditems_bydate(date) {
  $.get('/models/classdefs/schedule_by_day/' + date)
   .done(  function(val) { data.scheditems = val;   } )
   .error( function(xhr) { alert(xhr.responseText); } )
}
