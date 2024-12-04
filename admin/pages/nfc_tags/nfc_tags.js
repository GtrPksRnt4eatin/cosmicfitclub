data = {
  tags: [],
  value: "",
  customer: null
}

ctrl = {
  load_custy(custy) { data.customer = custy; },
  add_tag() { 
    $.post("/models/nfc", { value: data.value, customer_id: data.customer.id })
     .done(fetch_data);
  },
  del_tag(e,m) { 
    $.del(`/models/nfc/${m.tag.id}`)
     .done(fetch_data);
  }
}

$(document).ready(function() {
  userview = new UserView(id('userview_container'));
  rivets.bind(document.body, { data: data, ctrl: ctrl } );
  $.get("/models/nfc/all", function(tags) { data.tags = tags; });
});

function fetch_data() {
    $.get("/models/nfc/all", function(tags) { data.tags = tags; });  
}