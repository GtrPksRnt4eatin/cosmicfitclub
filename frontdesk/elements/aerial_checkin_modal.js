// ============================================================
//  aerial-checkin-modal  rivets component
//  Attrs: modal (shared modal state object), ctrl (page ctrl)
// ============================================================

function AerialCheckinModal(el, attr) {
  this.modal = attr.modal;
  this.ctrl  = attr.ctrl;

  this.load_styles();
}

AerialCheckinModal.prototype = {
  constructor: AerialCheckinModal
};

Object.assign(AerialCheckinModal.prototype, element);

AerialCheckinModal.prototype.HTML = `
  <div class='modal-overlay' rv-on-click='ctrl.close_modal'></div>
  <div class='modal-box'>

    <div class='modal-inner' rv-unless='modal.success'>
      <button class='modal-close' rv-on-click='ctrl.close_modal'>✕</button>
      <h2>Check In</h2>
      <div class='modal-name'>{ modal.slot | slot_name }</div>
      <div class='modal-time'>{ modal | modal_time }</div>
      <div class='modal-cost'>
        Cost: { modal.passes_needed } pass(es) or ${ modal.amount_cents | dollars }
      </div>
      <hr>

      <div rv-if='modal.customer'>
        <div class='pass-balance' rv-class-ok='modal | has_passes' rv-class-low='modal | lacks_passes'>
          { modal.customer.name } has { modal.customer.num_passes | passes_label } passes
        </div>
        <button class='pay-btn passes-pay-btn'
                rv-if='modal | has_passes'
                rv-unless='modal.busy'
                rv-on-click='ctrl.pay_passes'>
          Pay with { modal.passes_needed } Pass(es)
        </button>
        <div class='pass-error' rv-if='modal | lacks_passes'>
          Not enough passes (need { modal.passes_needed })
        </div>
      </div>

      <div rv-unless='modal.customer'>
        <div class='pass-email-prompt'>
          <p>Enter your email to pay with passes:</p>
          <input type='email' rv-value='modal.lookup_email' placeholder='your@email.com' />
          <button class='pay-btn' rv-unless='modal.busy' rv-on-click='ctrl.lookup_passes'>
            Look Up Account
          </button>
        </div>
      </div>

      <hr>

      <div class='card-section'>
        <p>Or pay by card:</p>
        <button class='pay-btn card-pay-btn' rv-unless='modal.busy' rv-on-click='ctrl.pay_card'>
          Pay ${ modal.amount_cents | dollars } by Card
        </button>
        <div class='busy-msg' rv-if='modal.busy'>Processing…</div>
      </div>
    </div>

    <div class='success-message' rv-if='modal.success'>
      <div class='success-check'>✓</div>
      <div class='success-text'>Welcome, { modal.success_name }!</div>
      <div class='success-sub'>You're all set. Enjoy your session!</div>
      <button class='pay-btn' rv-on-click='ctrl.close_modal' style='margin-top:2em'>Close</button>
    </div>

  </div>
`.untab(2);

AerialCheckinModal.prototype.CSS = `
  aerial-checkin-modal {
    display: flex;
    position: fixed;
    inset: 0;
    z-index: 1000;
    align-items: center;
    justify-content: center;
  }

  .modal-overlay {
    position: absolute;
    inset: 0;
    background: rgba(0,0,0,0.75);
    cursor: pointer;
  }

  .modal-box {
    position: relative;
    z-index: 1;
    background: #1a1a2e;
    border: 1px solid rgba(150,150,255,0.3);
    border-radius: 1.25em;
    padding: 2.5em;
    width: min(90vw, 480px);
    box-shadow: 0 0 4em rgba(80,80,200,0.3);
    max-height: 90vh;
    overflow-y: auto;
  }

  .modal-inner h2 { margin: 0 0 0.5em 0; font-size: 1.6em; color: #a0a0ff; }

  .modal-close {
    position: absolute;
    top: 1em; right: 1em;
    background: rgba(255,255,255,0.1);
    border: none; color: #fff;
    font-size: 1.2em; width: 2em; height: 2em;
    border-radius: 50%;
    cursor: pointer; font-family: inherit; line-height: 1;
  }

  .modal-name  { font-size: 1.3em; margin-bottom: 0.25em; }
  .modal-time  { font-size: 1em; color: rgba(255,255,255,0.6); margin-bottom: 0.25em; }
  .modal-cost  { font-size: 1em; color: #a0a0ff; margin-bottom: 0.5em; }
  .modal-box hr { border: none; border-top: 1px solid rgba(255,255,255,0.1); margin: 1.25em 0; }

  .pass-balance           { margin-bottom: 0.75em; }
  .pass-balance.ok        { color: #50c864; }
  .pass-balance.low       { color: #ff8050; }
  .pass-error             { color: #ff8050; font-size: 0.95em; margin-bottom: 0.5em; }

  .pass-email-prompt p    { margin: 0 0 0.5em 0; color: rgba(255,255,255,0.7); }
  .pass-email-prompt input[type='email'] {
    width: 100%;
    background: rgba(255,255,255,0.08);
    border: 1px solid rgba(255,255,255,0.2);
    border-radius: 0.5em; color: #fff;
    font-size: 1em; padding: 0.6em 0.9em;
    font-family: inherit; margin-bottom: 0.75em; outline: none;
  }
  .pass-email-prompt input[type='email']:focus { border-color: #a0a0ff; }

  .pay-btn {
    width: 100%;
    background: rgba(255,255,255,0.1);
    border: 1px solid rgba(255,255,255,0.2);
    color: #fff; font-size: 1em;
    padding: 0.75em 1em; border-radius: 0.6em;
    cursor: pointer; font-family: inherit;
    transition: background 0.2s; margin-bottom: 0.5em;
  }
  .pay-btn:hover          { background: rgba(255,255,255,0.18); }
  .pay-btn:active         { background: rgba(255,255,255,0.25); }
  .pay-btn:disabled       { opacity: 0.5; cursor: not-allowed; }
  .passes-pay-btn         { background: rgba(80,200,100,0.2); border-color: rgba(80,200,100,0.4); }
  .passes-pay-btn:hover   { background: rgba(80,200,100,0.3); }
  .card-pay-btn           { background: rgba(100,100,255,0.2); border-color: rgba(100,100,255,0.4); }
  .card-pay-btn:hover     { background: rgba(100,100,255,0.3); }
  .card-section p         { margin: 0 0 0.75em 0; color: rgba(255,255,255,0.7); }
  .busy-msg               { color: rgba(255,255,255,0.5); font-style: italic; padding: 0.5em 0; }

  .success-message { text-align: center; padding: 1em 0; }
  .success-check   { font-size: 4em; color: #50c864; margin-bottom: 0.25em; }
  .success-text    { font-size: 1.8em; margin-bottom: 0.25em; }
  .success-sub     { color: rgba(255,255,255,0.55); font-size: 1em; }
`.untab(2);

rivets.components['aerial-checkin-modal'] = {
  template:   function()        { return AerialCheckinModal.prototype.HTML; },
  initialize: function(el,attr) { return new AerialCheckinModal(el, attr);  }
};
