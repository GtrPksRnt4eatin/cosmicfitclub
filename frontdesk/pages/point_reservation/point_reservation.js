// ============================================================
//  Point Reservation Edit Page
// ============================================================

var data = { res: null, dirty: false };
var ctrl;
var popupmenu, payment_form, custy_selector, userview;

var APPARATUSES = [
  { label: 'Bringing My Own', value: 'other'         },
  { label: 'Straps',          value: 'Straps'        },
  { label: 'Silks',           value: 'Silks'         },
  { label: 'Hammock',         value: 'Hammock'       },
  { label: 'Lyra',            value: 'Lyra'          },
  { label: 'Spotting Belt',   value: 'Spotting Belt' }
];

// ---- Init --------------------------------------------------

$(document).ready(function () {
  popupmenu     = new PopupMenu(id('popupmenu_container'));
  payment_form  = new PaymentForm();
  custy_selector = new CustySelector(null, true, false);
  userview      = new UserView(id('userview_container'));

  payment_form.customer_facing();
  payment_form.ev_sub('show', popupmenu.show);
  payment_form.ev_sub('hide', popupmenu.hide);

  custy_selector.ev_sub('show',        popupmenu.show);
  custy_selector.ev_sub('close_modal', popupmenu.hide);

  ctrl = {
    save:                 save_reservation,
    cancel_reservation:   cancel_reservation,
    add_slot:             add_slot
  };

  load_reservation();
});

// ---- Load --------------------------------------------------

function load_reservation() {
  $.get('/models/groups/' + RES_ID, function (res) {
    data.res = res;
    render_reservation();
    render_slots();
    id('slots-tile').classList.remove('hidden');
    id('actions-tile').classList.remove('hidden');
  }, 'json').fail(function (e) {
    id('res-details').innerHTML = '<div class="error">Failed to load reservation: ' + (e.responseText || e.status) + '</div>';
  });
}

// ---- Render ------------------------------------------------

function render_reservation() {
  var res   = data.res;
  var start = moment(res.start_time);
  var end   = moment(res.end_time);
  var dur   = Math.round((new Date(res.end_time) - new Date(res.start_time)) / 3600000 * 2) / 2; // half-hour precision

  var html = '';

  html += '<div class="field-grid">';

  // Date + start time
  html += field_row('Date', '<input type="date" id="field-date" class="edit-input" value="' + start.format('YYYY-MM-DD') + '">');
  html += field_row('Start Time', '<input type="time" id="field-start" class="edit-input" value="' + start.format('HH:mm') + '">');

  // Duration selector
  var dur_opts = [0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4].map(function (v) {
    var label = v === 1 ? '1 hour' : (Number.isInteger(v) ? v + ' hours' : v + ' hours');
    var sel   = v === dur ? ' selected' : '';
    return '<option value="' + v + '"' + sel + '>' + label + '</option>';
  }).join('');
  html += field_row('Duration', '<select id="field-duration" class="edit-input">' + dur_opts + '</select>');

  // Apparatus
  var app_opts = APPARATUSES.map(function (a) {
    var sel = a.value === res.activity ? ' selected' : '';
    return '<option value="' + a.value + '"' + sel + '>' + a.label + '</option>';
  }).join('');
  html += field_row('Apparatus', '<select id="field-apparatus" class="edit-input">' + app_opts + '</select>');

  // Is Lesson
  var lesson_checked = res.is_lesson ? ' checked' : '';
  html += field_row('Private Lesson', '<input type="checkbox" id="field-lesson"' + lesson_checked + '>');

  // Note
  html += field_row('Rigging Notes', '<textarea id="field-note" class="edit-input" rows="3">' + (res.note || '') + '</textarea>');

  html += '</div>';

  // Confirmation tag
  if (res.tag) {
    html += '<div class="conf-tag">Confirmation: <strong>' + res.tag + '</strong></div>';
  }

  id('res-details').innerHTML = html;
}

function field_row(label, control_html) {
  return '<div class="field-row"><label>' + label + '</label><div class="field-val">' + control_html + '</div></div>';
}

function render_slots() {
  var tbody = $('#slots-table tbody');
  tbody.empty();

  (data.res.slots || []).forEach(function (slot, i) {
    var row = $('<tr data-slot-id="' + slot.id + '">');

    // Name
    var name_td = $('<td class="slot-name">');
    name_td.text(slot.customer_string || 'TBD');
    name_td.on('click', function () { change_slot_customer(slot.id); });
    row.append(name_td);

    // Payment
    var pay_td = $('<td class="slot-payment">');
    if (slot.payment) {
      pay_td.html('<span class="paid">' + payment_label(slot.payment) + '</span>');
    } else {
      pay_td.html(
        '<button class="slot-btn pay-passes-btn" data-slot="' + i + '">Passes</button>' +
        '<button class="slot-btn pay-card-btn"   data-slot="' + i + '">Card</button>'
      );
    }
    row.append(pay_td);

    // Checkin
    var ci_td = $('<td class="slot-checkin">');
    if (slot.checkin) {
      var ci_time = moment(slot.checkin.created_at).format('h:mm A');
      ci_td.html('<span class="checked-in">✓ ' + ci_time + '</span>');
    } else {
      var ci_btn = $('<button class="slot-btn checkin-btn">Check In</button>');
      ci_btn.on('click', function () { checkin_slot(slot.id); });
      ci_td.append(ci_btn);
    }
    row.append(ci_td);

    // Remove
    var del_td = $('<td class="slot-del">');
    if (!slot.checkin) {
      var del_btn = $('<button class="slot-btn del-btn">✕</button>');
      del_btn.on('click', function () { remove_slot(slot.id); });
      del_td.append(del_btn);
    }
    row.append(del_td);

    tbody.append(row);
  });

  // Wire up pay buttons after render
  $('.pay-passes-btn').on('click', function () {
    var i = parseInt($(this).data('slot'));
    pay_slot_passes(data.res.slots[i]);
  });
  $('.pay-card-btn').on('click', function () {
    var i = parseInt($(this).data('slot'));
    pay_slot_card(data.res.slots[i]);
  });
}

function payment_label(payment) {
  if (payment.type === 'passes') return parseFloat(payment.amount / 1200).toFixed(1) + ' passes';
  return '$' + (payment.amount / 100).toFixed(2) + ' ' + payment.type;
}

// ---- Save --------------------------------------------------

function save_reservation() {
  var date     = id('field-date').value;
  var start    = id('field-start').value;
  var duration = parseFloat(id('field-duration').value);
  var start_dt = moment.tz(date + 'T' + start, 'America/New_York');
  var end_dt   = start_dt.clone().add(duration, 'hours');

  var payload = {
    start_time: start_dt.format(),
    end_time:   end_dt.format(),
    activity:   id('field-apparatus').value,
    note:       id('field-note').value,
    is_lesson:  id('field-lesson').checked
  };

  $.ajax({
    url:         '/models/groups/' + RES_ID,
    method:      'PUT',
    contentType: 'application/json',
    data:        JSON.stringify(payload)
  }).done(function (res) {
    data.res = res;
    render_reservation();
    render_slots();
    flash_success('Saved!');
  }).fail(function (e) {
    if (e.status === 409) {
      flash_error('⚠ Scheduling conflict — another reservation already occupies that time. Please choose a different time.');
    } else {
      flash_error('Save failed: ' + (e.responseText || 'Unknown error'));
    }
  });
}

// ---- Slots -------------------------------------------------

function add_slot() {
  custy_selector.show_modal(0, function (custy_id) {
    $.ajax({
      url:         '/models/groups/' + RES_ID + '/slots',
      method:      'POST',
      contentType: 'application/json',
      data:        JSON.stringify({ customer_id: custy_id })
    }).done(function () {
      reload_slots();
    }).fail(function (e) {
      alert('Could not add participant: ' + e.responseText);
    });
  });
}

function change_slot_customer(slot_id) {
  custy_selector.show_modal(0, function (custy_id) {
    $.ajax({
      url:         '/models/groups/slots/' + slot_id,
      method:      'PATCH',
      contentType: 'application/json',
      data:        JSON.stringify({ customer_id: custy_id })
    }).done(function () {
      reload_slots();
    }).fail(function (e) {
      alert('Could not update participant: ' + e.responseText);
    });
  });
}

function remove_slot(slot_id) {
  if (!confirm('Remove this participant?')) return;
  $.ajax({ url: '/models/groups/' + RES_ID + '/slots/' + slot_id, method: 'DELETE' })
    .done(function () { reload_slots(); })
    .fail(function (e) { alert('Could not remove: ' + e.responseText); });
}

function reload_slots() {
  $.get('/models/groups/' + RES_ID, function (res) {
    data.res = res;
    render_slots();
  }, 'json');
}

// ---- Payments ----------------------------------------------

function pay_slot_passes(slot) {
  var res          = data.res;
  var duration_hr  = Math.round((new Date(res.end_time) - new Date(res.start_time)) / 3600000);
  var passes_needed = duration_hr;

  if (!slot.customer_id) {
    alert('Please assign a customer to this slot before paying with passes.');
    return;
  }

  $.get('/models/customers/' + slot.customer_id + '/class_passes', function (passes) {
    if (passes < passes_needed) {
      alert(slot.customer_string + ' only has ' + parseFloat(passes).toFixed(1) + ' passes (need ' + passes_needed + ').');
      return;
    }
    if (!confirm('Deduct ' + passes_needed + ' pass' + (passes_needed !== 1 ? 'es' : '') + ' from ' + slot.customer_string + '?')) return;

    $.post('/models/groups/slots/' + slot.id + '/checkin', {
      payment_type: 'passes',
      customer_id:  slot.customer_id
    }, function () {
      reload_slots();
    }, 'json').fail(function (e) {
      alert('Payment failed: ' + e.responseText);
    });
  }, 'json');
}

function pay_slot_card(slot) {
  var res         = data.res;
  var duration_hr = Math.round((new Date(res.end_time) - new Date(res.start_time)) / 3600000);
  var amount      = duration_hr * 1200;
  var reason      = 'Aerial Point: ' + moment(res.start_time).format('MMM D h:mm A');

  payment_form.checkout(slot.customer_id || null, amount, reason, { type: 'rental' }, function (payment_id) {
    $.post('/models/groups/slots/' + slot.id + '/checkin', { payment_id: payment_id }, function () {
      reload_slots();
    }, 'json').fail(function (e) {
      alert('Checkin failed after payment: ' + e.responseText);
    });
  });
}

// ---- Checkin -----------------------------------------------

function checkin_slot(slot_id) {
  var slot = (data.res.slots || []).find(function (s) { return s.id === slot_id; });
  if (!slot) return;

  var res         = data.res;
  var duration_hr = Math.round((new Date(res.end_time) - new Date(res.start_time)) / 3600000);
  var passes_needed = duration_hr;

  // If already has payment, just record checkin
  if (slot.payment) {
    $.post('/models/groups/slots/' + slot_id + '/checkin', { payment_id: slot.payment_id }, function () {
      reload_slots();
    }, 'json');
    return;
  }

  // Choose payment method
  var method = confirm(
    'Pay with passes for ' + slot.customer_string + '?\n\nOK = Passes  |  Cancel = Card'
  );
  if (method) {
    pay_slot_passes(slot);
  } else {
    pay_slot_card(slot);
  }
}

// ---- Cancel Reservation ------------------------------------

function cancel_reservation() {
  if (!confirm('Cancel this entire reservation? This cannot be undone.')) return;
  $.ajax({ url: '/models/groups/' + RES_ID, method: 'DELETE' })
    .done(function () { window.location.href = '/frontdesk/aerial_checkin'; })
    .fail(function (e) { alert('Could not cancel: ' + e.responseText); });
}

// ---- Helpers -----------------------------------------------

function flash_success(msg) {
  flash(msg, 'flash-success');
}

function flash_error(msg) {
  flash(msg, 'flash-error');
}

function flash(msg, cls) {
  // Remove any existing flash
  document.querySelectorAll('.flash-success, .flash-error').forEach(function (el) { el.remove(); });
  var el = document.createElement('div');
  el.className = cls;
  el.textContent = msg;
  document.body.appendChild(el);
  if (cls === 'flash-success') {
    setTimeout(function () { el.remove(); }, 2500);
  }
  // Errors stay until dismissed
  el.addEventListener('click', function () { el.remove(); });
}
