function include_rivets_select() {

  rivets.binders['idselect'] = {
    bind: function(el) {
      this.chosen_instance = $(el).chosen({ search_contains: true })
      this.chosen_instance.change(function(e,val) {
        this.publish( parseInt(val.selected) );
        if(this.el.onchange) { setTimeout(this.el.onchange,100); }
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

  rivets.binders['selectize'] = {
    bind: function(el) {
      this.selectize_instance = $(el).selectize({
        onChange: function(val) {
          this.publish(val);
          if(this.el.onchange) { this.el.onchange(); }
        }.bind(this)
      })[0];
    },
    unbind: function(el) {
      var x = 5;
    },
    routine: function(el,value) {
      this.selectize_instance.setValue(value);
    },
    getValue: function(el) {
      return $(this.selectize_instance).val();
    }
  }

  rivets.binders['select'] = {
    bind: function(el) {
      this.chosen_instance = $(el).chosen({ search_contains: true });
      $(this.chosen_instance).trigger("chosen:updated");
      this.chosen_instance.change(function(e,val) { 
        console.log("Publishing: " + val.selected);
        this.publish(val.selected); 
        if(this.el.onchange) { this.el.onchange(); }
      }.bind(this));
    },
    unbind: function(el) {
      $(el).chosen("destroy");
    },
    routine: function(el,value) {
      console.log("routine: " + value);
      $(el).val(value);
      $(this.chosen_instance).trigger("chosen:updated");
    },
    getValue: function(el) {
      console.log("getVal: " + $(this.chosen_instance).val());
      return $(this.chosen_instance).val();
    }
  }

  rivets.binders['multiselect'] = {
    bind: function(el) {
      el.setAttribute('multiple', 'true');
      this.chosen_instance = $(el).chosen({ search_contains: true })
      this.chosen_instance.change(function(val) {
        this.publish(val);
        if(this.el.onchange) { this.el.onchange(); }
      }.bind(this));
    },
    unbind: function(el) {
      $(el).chosen("destroy");
    },
    routine: function(el,value) {
      $(el).val(value);
      //$(this.chosen_instance).trigger("chosen:updated");
    },
    getValue: function(el) {
      return $(this.chosen_instance).val();
    }
  }

}
