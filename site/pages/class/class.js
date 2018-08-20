ctrl = {

}

$(document).ready(function() {

  rivets.binders['bgimg'] = function(el, value){ el.style.setProperty("background", "url('" + value + "')" ); };
  rivets.bind( document.body, { data: data, ctrl: ctrl })

})