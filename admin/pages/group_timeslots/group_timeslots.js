
var daypilot, start, end, loft_calendar;

$(document).ready( function() {

  popupmenu      = new PopupMenu( id('popupmenu_container') );
  custy_selector = new CustySelector();

  custy_selector.ev_sub('show'       , popupmenu.show );
  custy_selector.ev_sub('close_modal', popupmenu.hide );
  custy_selector.show_add_form();
  
  //setup_daypilot();
  var view = rivets.bind($('body'), { data : {} } );

  loft_calendar = get_element(view,'loft-calendar');
  
});

window.addEventListener('pageshow', fetch_data);

function setup_daypilot() {
  start = (new Date).toISOString().split('T')[0];
  end = new Date(Date.now() + 7*24*60*60*1000).toISOString().split('T')[0];
  daypilot = new DayPilot.Calendar('daypilot', {
    viewType: "Days",
    days: 7,
    cellDuration: 30,
    cellHeight: 30,
    startDate:  start,
    headerDateFormat: "ddd MMM d",
    businessBeginsHour: 10,
    businessEndsHour: 23,
    dayBeginsHour: 10,
    dayEndsHour: 23,
    timeRangeSelectedHandling: "Disabled",
    eventDeleteHandling: "Disabled",
    eventMoveHandling: "Disabled",
    eventResizeHandling: "Disabled",
    eventHoverHandling: "Disabled",
    onBeforeEventRender:   function(args) {
      args.data.html = args.data.text.split(',').join(',<br/>');
    },
    onEventClick: function(args) {
      window.location = '/checkout/group/' + args.e.data.id;
    }
  });
  
  daypilot.init();
}

function fetch_data() {
  //daypilot.events.list = [];
  //daypilot.update();
 
  loft_calendar.refresh_data();
  //$.get(`/models/groups/range-admin/${start}/${end}`)
  //.success( function(val) {
  //  for(i=0; i<val.length; i++) {
   //   daypilot.events.add(val[i]);
   // }
  //  daypilot.update();
  //})
}
