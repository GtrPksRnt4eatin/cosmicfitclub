data = {
  email_list: null,
  daterange: '',
  classdef_ids: []
}

ctrl = {
  get_list(e,m) {
    matches = /(\d{4}-\d\d-\d\d) to (\d{4}-\d\d-\d\d)/.exec(data.daterange);
    params = { from: matches[1], to: matches[2], classdef_ids: data.classdef_ids };
    $.get('class_email_list', params, ctrl.on_list, 'json')
  },

  on_list(list) {
    list = $(list).map( function(i,val) { val.sendmail = true; return val; }).toArray();
    data.email_list = list;
  },

  export() {
    matches = /(\d{4}-\d\d-\d\d) to (\d{4}-\d\d-\d\d)/.exec(data.daterange);
    params = { from: matches[1], to: matches[2], classdef_ids: data.classdef_ids };
    window.location = 'class_email_list.csv?from=' + matches[1] + '&to=' + matches[2] + '&classdef_ids[]=' + data.classdef_ids.join('&classdef_ids[]=');
  }
}

$(document).ready(function() {
  initialize_rivets();
  $('.list').on('change','.checkbox', function() { data.email_list.push({}); data.email_list.pop(); });

});

function initialize_rivets() {
  include_rivets_dates();
  include_rivets_select();
  rivets.formatters.mailto = function(val) {
  	if(empty(val)) return "";
    var list = $(val).filter( function(i,val) { return( val.sendmail == true ) });
    var list = $(list).map(   function(i,val) { return(val.customer_email)     }).toArray();
    return('mailto:' + list.join(','))
  }
  rivets.bind(document.body, { data: data, ctrl: ctrl } );
}