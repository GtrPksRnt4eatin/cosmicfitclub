data = {
  range: ""
}

ctrl = {
  rangeselect: function(e,m) {
    var x = 5;
  }
}

$(document).ready(function() {
  include_rivets_dates();
  rivets.bind( document.body, { data: data, ctrl: ctrl } );
});