data = {
  roles: [],
  selected_role_id: 0,
  selected_role_name: "",
  selected_user_id: 0,
  selected_user_name: "",
  role_list: []
}

ctrl = {
  refresh_data: function() {
    $.get('/auth/roles/' + data.selected_role_id + '/list', function(role_list) { data.role_list = role_list; }, 'json');
  },

  choose_role: function(e,m) {
    data.selected_role_id = e.target.selectedOptions[0].value;
    data.selected_role_name = e.target.selectedOptions[0].innerText;
    ctrl.refresh_data();
  },

  choose_user: function(e,m) {
    data.selected_user_id = e.target.selectedOptions[0].value;
    data.selected_user_name = e.target.selectedOptions[0].innerText;
  },

  revoke_role: function(e,m) {
    var ack = confirm("Revoke Role: " + data.selected_role_name + "\r\nfrom " + m.user.customer_name + "?");
    if(!ack) return;
    $.del("/auth/users/" + m.user.user_id + "/roles/" + data.selected_role_id, ctrl.refresh_data );
  },

  assign_role: function(e,m) {
    var ack = confirm("Add Role: " + data.selected_role_name + "\r\nto " + data.selected_user_name + "?");
    if(!ack) return;
    $.post('/auth/roles/' + data.selected_role_id + '/assign_to/' + data.selected_user_id, ctrl.refresh_data );
  },

  create_role: function(e,m) {
    var name = prompt("Enter New Role Name:", "");
    $.post('/auth/roles', { name: name }, function() { location.reload(); });
  },

  delete_role: function(e,m) {
    if(data.role_list.length>0) { alert('Role Must Be Empty First'); return; }
    var ack = confirm("Really Delete Role: " + data.selected_role_name + "?");
    if(!ack) return;
    $.del("/auth/roles/" + data.selected_role_id, function() { location.reload(); } );
  }
}

$(document).ready(function() {

  rivets.bind(document.body, { data: data, ctrl: ctrl } );

  $('#customers').chosen();
  $('#roles').chosen();

  get_roles();

});

function get_roles() {
  $.get('/auth/roles', function(roles) { data.roles = roles; }, 'json');
}