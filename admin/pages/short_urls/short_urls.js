data = {
  short_urls: [],
  short_path: "",
  long_path: ""
}

ctrl = {
  add_url() {
    if (!data.short_path || !data.long_path) return;
    $.post("/models/short_urls", { short_path: data.short_path, long_path: data.long_path })
     .done(function() {
       data.short_path = "";
       data.long_path  = "";
       fetch_data();
     });
  },
  del_url(e, m) {
    if (!confirm(`Delete short URL "/${m.url.short_path}"?`)) return;
    $.del(`/models/short_urls/${m.url.id}`)
     .done(fetch_data);
  },
  remap_url(e, m) {
    m.url.editing = true;
  },
  cancel_edit(e, m) {
    m.url.editing = false;
    fetch_data();
  },
  save_url(e, m) {
    $.put(`/models/short_urls/${m.url.id}`, { short_path: m.url.short_path, long_path: m.url.long_path })
     .done(function() {
       m.url.editing = false;
       fetch_data();
     });
  }
}

$(document).ready(function() {
  userview = new UserView(id('userview_container'));
  rivets.bind(document.body, { data: data, ctrl: ctrl } );
  fetch_data();
});

function fetch_data() {
  $.get("/models/short_urls", function(urls) {
    urls.forEach(function(u) { u.editing = false; });
    data.short_urls = urls;
  });
}