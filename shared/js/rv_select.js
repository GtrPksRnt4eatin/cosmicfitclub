function include_rivets_select() {

  rivets.binders['idselect'] = {
    bind: function(el) {
      this.chosen_instance = $(el).chosen()
      this.chosen_instance.change(function(e,val) {
        this.publish( parseInt(val.selected) );
        if(this.el.onchange) { this.el.onchange(); }
      }.bind(this));
    },
    unbind: function(el) {
      $(el).chosen("destroy");
    },
    routine: function(el,value) {
      $(el).val(value);
      $(this.chosen_instance).trigger("chosen:updated");
    },
    getValue: function(el) {
      return $(this.chosen_instance).val();
    }
  }

  rivets.binders['select'] = {
    bind: function(el) {
      this.chosen_instance = $(el).chosen()
      this.chosen_instance.change(function(e,val) {
        this.publish(val.selected);
        if(this.el.onchange) { this.el.onchange(); }
      }.bind(this));
    },
    unbind: function(el) {
      $(el).chosen("destroy");
    },
    routine: function(el,value) {
      $(el).val(value);
      $(this.chosen_instance).trigger("chosen:updated");
    },
    getValue: function(el) {
      return $(this.chosen_instance).val();
    }
  }

}