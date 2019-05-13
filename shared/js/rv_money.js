function include_rivets_money() {

  rivets.formatters.money   = function(val) { return "$ " + (val/100).toFixed(2) };
  rivets.formatters.dollars = function(val) { return "$ " + val.toFixed(2) };

  rivets.binders['moneyfield'] = {

    bind: function(el) {
      this.priceformatInstance = $(el).priceFormat({ prefix: '$' });
      this.priceformatInstance.on('pricechange', function(val) { this.publish(val); }.bind(this) )
    },

    unbind: function(el) {
      this.priceformatInstance.unpriceFormat();
    },

    routine: function(el,value) {
      if(!empty(value)) { 
        this.priceformatInstance.val( value/100 );
        this.priceformatInstance.keyup();
      }
    },

    getValue: function(el) {
      return $(el).priceToFloat()*100;
    }

  }
}