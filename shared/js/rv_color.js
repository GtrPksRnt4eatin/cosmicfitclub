function include_rivets_color() {

  rivets.binders['color'] = {

    bind: function(el) {
      this.spectrumInstance = $(el).spectrum({
        showAlpha: true, 
        preferredFormat: "rgb",   
        change: function(color) {
          this.publish(color.toRgbString());
          if(this.el.onchange) { this.el.onchange(); }
        }.bind(this)
      })
    },

    unbind: function(el) {
      this.spectrumInstance.spectrum("destroy");
    },

    routine: function(el,value) {
      if(value) { 
        this.spectrumInstance.spectrum("set", value); 
      }
    },

    getValue: function(el) {
      return this.spectrumInstance.spectrum("get");
    }

  }

}