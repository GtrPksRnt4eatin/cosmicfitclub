// ============================================================
//  Aerial Point Kiosk Check-In
// ============================================================

var payment_form;
var popupmenu;

var state = {
  reservations: [],
  selected_slot: null,
  selected_res:  null,
  customer:      null,   // identified customer for pass payment
  busy:          false
};

// ---- Init --------------------------------------------------

$(document).ready(function () {
  payment_form = new PaymentForm();
  popupmenu    = new PopupMenu(id('popupmenu_container'));

  payment_form.customer_facing();
  payment_form.ev_sub('show', popupmenu.show);
  payment_form.ev_sub('hide', function (args) {
    popupmenu.hide(args);
    // Reset busy if the form is closed without completing payment
    if (!state._completing_checkin) { state.busy = false; }
  });

  tick_clock();
  setInterval(tick_clock, 1000);

  load_reservations();
  setInterval(load_reservations, 60000);
});

// ---- Clock -------------------------------------------------

function tick_clock() {
  var now = moment();
  id('clock').textContent = now.format('h:mm A') + '  ' + now.format('ddd, MMM D');
}

// ---- Data --------------------------------------------------

function load_reservations() {
  $.get('/models/groups/aerial_window', function (data) {
    state.reservations = data;
    render_timeline();
  }, 'json').fail(function () {
    // silently retry on next interval
  });
}

// ---- Render ------------------------------------------------

function render_timeline() {
  var now = new Date();

  var prev = [], curr = [], next = [];
  state.reservations.forEach(function (res) {
    var start = new Date(res.start_time);
    var end   = new Date(res.end_time);
    if (end <= now)        { prev.push(res); }
    else if (start <= now) { curr.push(res); }
    else                   { next.push(res); }
  });

  // Keep only the most recent previous
  prev = prev.slice(-1);
  // Keep only the first 3 upcoming
  next = next.slice(0, 3);

  render_section('prev-slots', prev, true);
  render_section('curr-slots', curr, false);
  render_section('next-slots', next, false);
}

function render_section(container_id, reservations, is_past) {
  var container = id(container_id);
  container.innerHTML = '';

  if (reservations.length === 0) {
    container.innerHTML = '<div class="empty-slot">—</div>';
    return;
  }

  reservations.forEach(function (res) {
    var card = make_res_card(res, is_past);
    container.appendChild(card);
  });
}

function make_res_card(res, is_past) {
  var start = moment(res.start_time);
  var end   = moment(res.end_time);
  var duration_hr = Math.round((new Date(res.end_time) - new Date(res.start_time)) / 3600000);

  var card = document.createElement('div');
  card.className = 'res-card' + (is_past ? ' past' : '');
  card.dataset.id = res.id;

  // Edit link (top right)
  var edit_a = document.createElement('a');
  edit_a.className = 'res-edit-link';
  edit_a.href = '/frontdesk/point_reservation/' + res.id;
  edit_a.textContent = 'Edit';
  card.appendChild(edit_a);

  // Time header
  var time_el = document.createElement('div');
  time_el.className = 'res-time';
  time_el.textContent = start.format('h:mm') + ' – ' + end.format('h:mm A');
  card.appendChild(time_el);

  var dur_el = document.createElement('div');
  dur_el.className = 'res-duration';
  dur_el.textContent = duration_hr + ' hr' + (duration_hr !== 1 ? 's' : '');
  card.appendChild(dur_el);

  // Slots
  var slots_el = document.createElement('div');
  slots_el.className = 'res-slots';

  (res.slots || []).forEach(function (slot) {
    var slot_el = document.createElement('div');
    slot_el.className = 'slot-row' + (slot.checkin ? ' checked-in' : '');
    slot_el.dataset.slot_id = slot.id;

    var name_el = document.createElement('span');
    name_el.className = 'slot-name';
    name_el.textContent = slot.customer_string || 'Guest';
    slot_el.appendChild(name_el);

    if (slot.checkin) {
      var badge = document.createElement('span');
      badge.className = 'checkin-badge';
      badge.textContent = '✓ Checked In';
      slot_el.appendChild(badge);
    } else if (!is_past) {
      var btn = document.createElement('button');
      btn.className = 'checkin-btn';
      btn.textContent = 'Check In';
      btn.addEventListener('click', function (e) {
        e.stopPropagation();
        open_checkin_modal(res, slot);
      });
      slot_el.appendChild(btn);
    }

    slots_el.appendChild(slot_el);
  });

  card.appendChild(slots_el);
  return card;
}

// ---- Check-In Modal ----------------------------------------

function open_checkin_modal(res, slot) {
  state.selected_res  = res;
  state.selected_slot = slot;
  state.customer      = null;
  state.busy          = false;

  var duration_hr  = Math.round((new Date(res.end_time) - new Date(res.start_time)) / 3600000);
  var passes_needed = duration_hr;
  var amount_cents  = passes_needed * 1200;

  var html = '<div class="modal-inner">';
  html += '<button class="modal-close" onclick="close_checkin_modal()">✕</button>';
  html += '<h2>Check In</h2>';
  html += '<div class="modal-name">' + (slot.customer_string || 'Guest') + '</div>';
  html += '<div class="modal-time">'
        + moment(res.start_time).format('h:mm A') + ' – '
        + moment(res.end_time).format('h:mm A')
        + ' &nbsp;(' + duration_hr + ' hr' + (duration_hr !== 1 ? 's' : '') + ')'
        + '</div>';
  html += '<div class="modal-cost">Cost: ' + passes_needed + ' pass' + (passes_needed !== 1 ? 'es' : '') + ' or $' + (amount_cents / 100).toFixed(2) + '</div>';
  html += '<hr>';

  // Pass payment section
  html += '<div id="pass-section">';
  if (slot.customer_id) {
    html += '<div id="pass-lookup">';
    html += '<div class="pass-loading">Loading pass balance…</div>';
    html += '</div>';
  } else {
    html += '<div class="pass-email-prompt">';
    html += '<p>Enter your email to pay with passes:</p>';
    html += '<input type="email" id="pass-email" placeholder="your@email.com" />';
    html += '<button class="pay-btn" onclick="lookup_customer_for_passes(' + passes_needed + ')">Look Up Account</button>';
    html += '</div>';
  }
  html += '</div>';

  html += '<hr>';
  html += '<div class="card-section">';
  html += '<p>Or pay by card:</p>';
  html += '<button class="pay-btn card-pay-btn" onclick="pay_by_card(' + amount_cents + ')">Pay $' + (amount_cents / 100).toFixed(2) + ' by Card</button>';
  html += '</div>';

  html += '</div>';

  id('modal-content').innerHTML = html;
  id('checkin-modal').classList.remove('hidden');

  // If slot has a customer_id, load their passes immediately
  if (slot.customer_id) {
    $.get('/models/customers/' + slot.customer_id + '/class_passes', function (passes) {
      state.customer = { id: slot.customer_id, name: slot.customer_string, num_passes: passes };
      render_pass_section(passes_needed);
    }, 'json').fail(function () {
      id('pass-lookup').innerHTML = '<div class="pass-error">Could not load pass balance.</div>';
    });
  }
}

function render_pass_section(passes_needed) {
  if (!state.customer) return;
  var passes = state.customer.num_passes;
  var has_enough = passes >= passes_needed;
  var html = '<div class="pass-balance ' + (has_enough ? 'ok' : 'low') + '">';
  html += state.customer.name + ' has <strong>' + parseFloat(passes).toFixed(1) + ' passes</strong>';
  html += '</div>';
  if (has_enough) {
    html += '<button class="pay-btn passes-pay-btn" onclick="pay_by_passes(' + passes_needed + ')">Pay with ' + passes_needed + ' Pass' + (passes_needed !== 1 ? 'es' : '') + '</button>';
  } else {
    html += '<div class="pass-error">Not enough passes (need ' + passes_needed + ').</div>';
  }
  id('pass-lookup').innerHTML = html;
}

function close_checkin_modal() {
  id('checkin-modal').classList.add('hidden');
  id('modal-content').innerHTML = '';
  state.selected_slot = null;
  state.selected_res  = null;
  state.customer      = null;
}

// ---- Customer Lookup for Passes ----------------------------

function lookup_customer_for_passes(passes_needed) {
  var email = (id('pass-email').value || '').trim();
  if (!email) { alert('Please enter your email.'); return; }

  $.get('/models/groups/customer_lookup?email=' + encodeURIComponent(email), function (data) {
    state.customer = data;
    id('pass-lookup') || (function () {
      var ps = id('pass-section');
      ps.innerHTML = '<div id="pass-lookup"></div>';
    })();
    render_pass_section(passes_needed);
  }, 'json').fail(function (e) {
    if (e.status === 404) {
      alert('No account found for that email. Please pay by card.');
    } else {
      alert('Error looking up account. Please try again.');
    }
  });
}

// ---- Payment -----------------------------------------------

function pay_by_passes(passes_needed) {
  if (state.busy) return;
  if (!state.customer) { alert('No customer identified.'); return; }
  if (!state.selected_slot) return;
  state.busy = true;

  disable_buttons();

  do_checkin('passes', state.customer.id, null);
}

function pay_by_card(amount_cents) {
  if (state.busy) return;
  if (!state.selected_slot) return;
  state.busy = true;

  var custy_id = state.customer ? state.customer.id : null;
  var reason   = 'Aerial Point: ' + moment(state.selected_res.start_time).format('MMM D h:mm A');

  payment_form.checkout(custy_id, amount_cents, reason, { type: 'rental' }, function (payment_id) {
    do_checkin('card', null, payment_id);
  });
}

function do_checkin(payment_type, customer_id, payment_id) {
  var slot_id = state.selected_slot.id;
  var body = { payment_type: payment_type };
  if (customer_id) body.customer_id = customer_id;
  if (payment_id)  body.payment_id  = payment_id;

  state._completing_checkin = true;

  $.post('/models/groups/slots/' + slot_id + '/checkin', body, function (updated_slot) {
    state.busy = false;
    state._completing_checkin = false;
    close_checkin_modal();
    show_success_message(updated_slot.customer_string || 'Guest');
    load_reservations();
  }, 'json').fail(function (e) {
    state.busy = false;
    state._completing_checkin = false;
    alert('Check-in failed: ' + (e.responseText || 'Unknown error'));
    enable_buttons();
  });
}

function disable_buttons() {
  $('.pay-btn').prop('disabled', true).addClass('busy');
}

function enable_buttons() {
  $('.pay-btn').prop('disabled', false).removeClass('busy');
}

function show_success_message(name) {
  id('modal-content').innerHTML =
    '<div class="success-message">' +
    '<div class="success-check">✓</div>' +
    '<div class="success-text">Welcome, ' + name + '!</div>' +
    '<div class="success-sub">You\'re all set. Enjoy your session!</div>' +
    '<button class="pay-btn" onclick="close_checkin_modal()" style="margin-top:2em">Close</button>' +
    '</div>';
  id('checkin-modal').classList.remove('hidden');
  // Auto-close after 5 seconds
  setTimeout(close_checkin_modal, 5000);
}

// ---- Helpers -----------------------------------------------

ctrl = {
  close_modal: function (e) {
    if (e.target.id === 'checkin-modal' || e.target.classList.contains('modal-overlay')) {
      close_checkin_modal();
    }
  }
};
