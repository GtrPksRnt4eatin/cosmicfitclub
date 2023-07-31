
var daypilot;

$(document).ready( function() {

  popupmenu      = new PopupMenu( id('popupmenu_container') );
  custy_selector = new CustySelector();

  custy_selector.ev_sub('show'       , popupmenu.show );
  custy_selector.ev_sub('close_modal', popupmenu.hide );
  custy_selector.show_add_form();
  
  setup_daypilot();
  
});

  function setup_daypilot() {
    let start = (new Date).toISOString().split('T')[0];
    let end = new Date(Date.now() + 7*24*60*60*1000).toISOString().split('T')[0];
    daypilot = new DayPilot.Calendar('daypilot', {
      viewType: "Days",
      days: 7,
      cellDuration: 30,
      cellHeight: 40,
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
        window.location = '/checkout/group/' + args.data.id;
      }
    });
  
    $.get(`/models/groups/range-admin/${start}/${end}`)
    .success( function(val) {
      for(i=0; i<val.length; i++) {
        daypilot.events.add(val[i]);
      }
    })
  
    daypilot.init();
  }
