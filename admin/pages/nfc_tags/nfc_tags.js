data = {
  tags: []
}

ctrl = {
}

$(document).ready(function() {
  rivets.bind(document.body, { data: data, ctrl: ctrl } );
  $.get("/models/nfc/all", function(tags) { data.tags = tags; });
});