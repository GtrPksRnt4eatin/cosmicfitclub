data = {
  short_urls: [],
  short_path: "",
  long_path: ""
}

ctrl = {
  add_url() { 
    $.post("/models/short_urls", { value: data.value })
     .done(fetch_data);
  },
  del_url(e,m) { 
    $.del(`/models/short_urls/${m.url.id}`)
     .done(fetch_data);
  }
}

$(document).ready(function() {
  userview = new UserView(id('userview_container'));
  rivets.bind(document.body, { data: data, ctrl: ctrl } );
  fetch_data();
});

function fetch_data() {
  $.get("/models/short_urls", function(urls) { data.short_urls = urls; });  
}