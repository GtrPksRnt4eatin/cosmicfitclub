data = {
  tags: []
}

ctrl = {
  load_custy(custy) { data.customer = custy; },
  add_tag() { 
    let x = 5;
  },
  del_tag(e,m) { 
    let x=5;
  }
}

$(document).ready(function() {
  rivets.bind(document.body, { data: data, ctrl: ctrl } );
  $.get("/models/nfc/all", function(tags) { data.tags = tags; });
});