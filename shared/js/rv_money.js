function include_rivets_money() {

  rivets.formatters.money = function(val) { return `$ ${ val == 0 ? 0 : val/100 }.00` };

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