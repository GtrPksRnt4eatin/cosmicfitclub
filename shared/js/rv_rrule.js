function include_rivets_rrule() {

  rivets.formatters.rrule = function(val) {
    switch(val) {
      case 'FREQ=WEEKLY;BYDAY=MO;INTERVAL=1': 
        return "Mondays";
      case 'FREQ=WEEKLY;BYDAY=TU;INTERVAL=1':
        return "Tuesdays";
      case 'FREQ=WEEKLY;BYDAY=WE;INTERVAL=1':
        return "Wednesdays";
      case 'FREQ=WEEKLY;BYDAY=TH;INTERVAL=1':
        return "Thursdays";
      case 'FREQ=WEEKLY;BYDAY=FR;INTERVAL=1':
        return "Fridays";
      case 'FREQ=WEEKLY;BYDAY=SA;INTERVAL=1':
        return "Saturdays";
      case 'FREQ=WEEKLY;BYDAY=SU;INTERVAL=1':
        return "Sundays";
      default:
        return val;
    }
  }
  
}