element_modal = {

  instances: [],

  show_popup: function(content) {
    instances.push( $(document.body).appendChild(content) );
  },

  hide_popup: function() {
  	instances
  },

  initialize: function() {
  	// ensure container is in document
  }

}