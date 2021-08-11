
var daypilot;

$(document).ready( function() {
  setup_daypilot();
});

  function setup_daypilot() {
    daypilot = new DayPilot.Calendar('daypilot', {
      viewType: "Days",
      days: 7,
      cellDuration: 30,
      cellHeight: 40,
      startDate:  "2021-08-09",
      headerDateFormat: "ddd MMM d",
      businessBeginsHour: 11,
      businessEndsHour: 23,
      dayBeginsHour: 11,
      dayEndsHour: 23,
      timeRangeSelectedHandling: "Disabled",
      eventDeleteHandling: "Disabled",
      eventMoveHandling: "Disabled",
      eventResizeHandling: "Disabled",
      eventClickHandling: "Disabled",
      eventHoverHandling: "Disabled",
      onBeforeEventRender:   function(args) {
        args.data.html = args.data.text.split(',').join(',<br/>');
      }
    });
  
    $.get("/models/groups/range-admin/2021-08-09/2021-08-16")
    .success( function(val) {
      for(i=0; i<val.length; i++) {
        daypilot.events.add(val[i]);
      }
    })
  
    daypilot.init();
  }