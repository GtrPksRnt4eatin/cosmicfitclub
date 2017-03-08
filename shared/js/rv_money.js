function include_rivets_money() {
  rivets.formatters.money = function(val) { 
  	return `$ ${ val == 0 ? 0 : val/100 }.00` };
}