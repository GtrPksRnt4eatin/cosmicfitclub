data = {
  range: ""
}

ctrl = {
  rangeselect: function(e,m) {
    var x = 5;
  }
}

$(document).ready(function() {
  rivets.bind( document.body, { data: data, ctrl: ctrl } );
});