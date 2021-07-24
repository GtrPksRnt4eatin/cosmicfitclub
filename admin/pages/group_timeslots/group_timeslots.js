
var daypilot;

$(document).ready( function() {
  setup_daypilot();
});

  function setup_daypilot() {
    daypilot = new DayPilot.Calendar('daypilot', {
      viewType: "Days",
      days: 5,
      cellDuration: 30,
      cellHeight: 25,
      startDate:  "2021-08-09",
      headerDateFormat: "ddd MMM d",
      businessBeginsHour: 15,
      businessEndsHour: 22,
      dayBeginsHour: 15,
      dayEndsHour: 22,
      timeRangeSelectedHandling: "Disabled",
      eventDeleteHandling: "Disabled",
      eventMoveHandling: "Disabled",
      eventResizeHandling: "Disabled",
      eventClickHandling: "Disabled",
      eventHoverHandling: "Disabled",
      onBeforeCellRender:   function(args) {
        var x = 5;
      }
    });
  
    $.get("/models/groups/range-admin/2021-08-09/2021-08-14")
    .success( function(val) {
      for(i=0; i<val.length; i++) {
        daypilot.events.add(val[i]);
      }
    })
  
    daypilot.init();
  }