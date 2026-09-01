// ============================================================
//  aerial-timeline  rivets component
//  Attrs: prev, curr, next (reservation arrays), ctrl (page ctrl)
// ============================================================

function AerialTimeline(el, attr) {
  this.prev = attr.prev;
  this.curr = attr.curr;
  this.next = attr.next;
  this.ctrl = attr.ctrl;

  this.load_styles();
}

AerialTimeline.prototype = {
  constructor: AerialTimeline
};

Object.assign(AerialTimeline.prototype, element);

AerialTimeline.prototype.HTML = `
  <div class='section'>
    <h3>Previous</h3>
    <div class='empty-slot' rv-hide='prev.0'>—</div>
    <div class='res-card past' rv-each-res='prev'>
      <a class='res-edit-link' rv-href='res | edit_href'>Edit</a>
      <div class='res-time'>{ res | res_time }</div>
      <div class='res-duration'>{ res | res_dur }</div>
      <div class='res-slots'>
        <div class='slot-row checked-in' rv-each-slot='res.slots'>
          <span class='slot-name' rv-title='slot | slot_id_title'>{ slot | slot_name }</span>
          <span class='checkin-badge' rv-show='slot.checkin'>✓ Checked In</span>
        </div>
      </div>
    </div>
  </div>

  <div class='section current-section'>
    <h3>Now</h3>
    <div class='empty-slot' rv-hide='curr.0'>—</div>
    <div class='res-card' rv-each-res='curr'>
      <a class='res-edit-link' rv-href='res | edit_href'>Edit</a>
      <div class='res-time'>{ res | res_time }</div>
      <div class='res-duration'>{ res | res_dur }</div>
      <div class='res-slots'>
        <div rv-class-checked-in='slot.checkin' class='slot-row' rv-each-slot='res.slots'>
          <span class='slot-name' rv-title='slot | slot_id_title'>{ slot | slot_name }</span>
          <span class='checkin-badge' rv-show='slot.checkin'>✓ Checked In</span>
          <button class='checkin-btn' rv-hide='slot.checkin' rv-on-click='ctrl.open_modal'>Check In</button>
        </div>
      </div>
    </div>
  </div>

  <div class='section'>
    <h3>Up Next</h3>
    <div class='empty-slot' rv-hide='next.0'>—</div>
    <div class='res-card' rv-each-res='next'>
      <a class='res-edit-link' rv-href='res | edit_href'>Edit</a>
      <div class='res-time'>{ res | res_time }</div>
      <div class='res-duration'>{ res | res_dur }</div>
      <div class='res-slots'>
        <div rv-class-checked-in='slot.checkin' class='slot-row' rv-each-slot='res.slots'>
          <span class='slot-name' rv-title='slot | slot_id_title'>{ slot | slot_name }</span>
          <span class='checkin-badge' rv-show='slot.checkin'>✓ Checked In</span>
          <button class='checkin-btn' rv-hide='slot.checkin' rv-on-click='ctrl.open_modal'>Check In</button>
        </div>
      </div>
    </div>
  </div>
`.untab(2);

AerialTimeline.prototype.CSS = `
  aerial-timeline {
    display: contents;
  }

  .res-card {
    background: rgba(40,40,65,0.9);
    box-shadow: 0 0 6px rgba(255,255,255,0.1);
    border-radius: 0.75em;
    padding: 1.25em;
    margin-bottom: 1em;
    position: relative;
  }

  .res-card.past { opacity: 0.45; }

  .res-edit-link {
    position: absolute;
    top: 0.9em; right: 0.9em;
    font-size: 0.75em;
    color: rgba(160,160,255,0.6);
    text-decoration: none;
    padding: 0.2em 0.5em;
    border: 1px solid rgba(160,160,255,0.2);
    border-radius: 0.3em;
  }
  .res-edit-link:hover { background: rgba(160,160,255,0.1); color: #a0a0ff; }

  .res-time     { font-size: 1.4em; font-weight: bold; margin-bottom: 0.15em; }
  .res-duration { font-size: 0.85em; color: rgba(255,255,255,0.5); margin-bottom: 0.9em; }

  .res-slots { display: flex; flex-direction: column; gap: 0.5em; }

  .slot-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    background: rgba(50,50,80,0.7);
    border-radius: 0.5em;
    padding: 0.6em 0.9em;
    gap: 0.75em;
  }
  .slot-row.checked-in { background: rgba(30,90,50,0.8); border: 1px solid rgba(50,200,100,0.4); }

  .slot-name    { font-size: 1.05em; flex: 1; }
  .checkin-badge { font-size: 0.8em; color: #50c864; white-space: nowrap; }

  .checkin-btn {
    background: linear-gradient(135deg, #6060ff, #a050ff);
    color: #fff;
    border: none;
    border-radius: 0.5em;
    padding: 0.5em 1em;
    font-size: 0.9em;
    cursor: pointer;
    font-family: inherit;
    white-space: nowrap;
    transition: opacity 0.2s;
  }
  .checkin-btn:hover  { opacity: 0.85; }
  .checkin-btn:active { opacity: 0.7;  }
`.untab(2);

rivets.components['aerial-timeline'] = {
  template:   function()        { return AerialTimeline.prototype.HTML; },
  initialize: function(el,attr) { return new AerialTimeline(el, attr);  }
};
