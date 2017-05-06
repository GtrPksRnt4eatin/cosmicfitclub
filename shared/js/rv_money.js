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

  rivets.binders['cardfield'] = {

    bind: function(el) {
      this.flatpickrInstance = $(el).flatpickr({
        enableTime: true, 
        altInput: true, 
        altFormat: 'm/d/Y h:i K',
        onChange: function(val) {
          this.publish(val);
          if(this.el.onchange) { this.el.onchange(); }
        }.bind(this)
      })
    },

    unbind: function(el) {
      this.flatpickrInstance.destroy();
    },

    routine: function(el,value) {
      if(value) { 
        this.flatpickrInstance.setDate( value ); 
        this.flatpickrInstance.jumpToDate(value);
      }
    },

    getValue: function(el) {
      return el.value;
    }

  }

}