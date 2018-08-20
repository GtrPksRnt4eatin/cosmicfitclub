ctrl = {

}

$(document).ready(function() {

  rivets.binders['bgimg'] = function(el, value){ el.style.setProperty("BackgroundImage", value); };
  rivets.bind( document.body, { data: data, ctrl: ctrl })

})