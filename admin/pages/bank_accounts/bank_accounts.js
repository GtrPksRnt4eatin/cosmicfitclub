data = {
  accounts: [],
  start_date: '',
  end_date: '',
  message: '',
  stripe_pnl_generating: false,
  stripe_pnl_button_text: 'Generate Stripe P&L Sheet'
}

ctrl = {
  add_account: function() {
    data.message = 'Creating link token...';
    $.ajax({
      url: '/integrations/plaid/link_token',
      type: 'POST',
      data: JSON.stringify({ user_id: 'admin-' + Date.now() }),
      contentType: 'application/json',
      success: function(resp) {
        open_plaid_link(resp.link_token);
      },
      error: function(xhr) {
        data.message = parse_error(xhr, 'Failed to create Plaid Link token');
      }
    });
  },

  download_csv: function(e, m) {
    var accountId = m && m.account && m.account.account_id ? m.account.account_id : '';
    if (!accountId) { return; }

    var qs = $.param({
      account_id: accountId,
      start_date: data.start_date,
      end_date: data.end_date
    });

    window.location = '/integrations/plaid/transactions.csv?' + qs;
  },

  remove_account: function(e, m) {
    var accountId = m && m.account && m.account.account_id ? m.account.account_id : '';
    if (!accountId) { return; }

    if (!window.confirm('Remove this linked account?')) { return; }

    $.ajax({
      url: '/integrations/plaid/remove_account',
      type: 'POST',
      data: JSON.stringify({ account_id: accountId }),
      contentType: 'application/json',
      success: function(resp) {
        var removed = resp && resp.removed ? resp.removed : 0;
        data.message = removed > 0 ? 'Account removed.' : 'Account not found.';
        data.accounts = (resp && resp.accounts) ? resp.accounts : [];
      },
      error: function(xhr) {
        data.message = parse_error(xhr, 'Failed to remove account');
      }
    });
  },

  generate_stripe_pnl: function() {
    if(data['stripe_pnl_generating']) { return; }
    if(!(data['start_date'] && data['end_date'])) {
      data.message = 'Select a start and end date first.';
      return;
    }

    set_stripe_pnl_generating(true);
    data.message = 'Starting Stripe P&L generation...';

    $.get('/models/staff/stripe_pnl_sheet', { from: data['start_date'], to: data['end_date'] })
      .done(function(resp) {
        if(resp && resp.job_id) {
          poll_stripe_pnl_job(resp.job_id, 0);
          return;
        }
        if(resp && resp.url) {
          set_stripe_pnl_generating(false);
          window.location = resp.url;
          return;
        }
        set_stripe_pnl_generating(false);
        data.message = 'Stripe P&L job started, but no job id was returned.';
      })
      .fail(function(xhr) {
        set_stripe_pnl_generating(false);
        data.message = parse_error(xhr, 'Failed to create Stripe P&L sheet');
      });
  }
}

$(document).ready(function() {
  userview = new UserView(id('userview_container'));

  init_dates();

  rivets.formatters.fallback = function(primary, backup) {
    if (primary === null || primary === undefined || String(primary).trim() === '') {
      return backup || '';
    }
    return primary;
  };

  rivets.bind(document.body, { data: data, ctrl: ctrl });

  load_accounts();
});

function init_dates() {
  var today = new Date();
  var monthAgo = new Date(today.getFullYear(), today.getMonth() - 1, today.getDate());
  data.end_date = to_iso_date(today);
  data.start_date = to_iso_date(monthAgo);
}

function to_iso_date(d) {
  var mm = String(d.getMonth() + 1).padStart(2, '0');
  var dd = String(d.getDate()).padStart(2, '0');
  return d.getFullYear() + '-' + mm + '-' + dd;
}

function load_accounts() {
  $.get('/integrations/plaid/accounts', function(resp) {
    data.accounts = normalize_accounts(resp && resp.accounts ? resp.accounts : []);
    data.message = data.accounts.length ? '' : 'No linked accounts yet.';
  }).fail(function(xhr) {
    data.message = parse_error(xhr, 'Failed to load linked accounts');
  });
}

function normalize_accounts(value) {
  if (Array.isArray(value)) { return value; }

  if (typeof value === 'string') {
    try {
      var parsed = JSON.parse(value);
      return normalize_accounts(parsed);
    } catch (e) {
      return [];
    }
  }

  if (value && typeof value === 'object') {
    if (Array.isArray(value.accounts)) {
      return value.accounts;
    }
    return Object.keys(value).map(function(key) { return value[key]; });
  }

  return [];
}

function open_plaid_link(linkToken) {
  var handler = Plaid.create({
    token: linkToken,
    onSuccess: function(publicToken) {
      data.message = 'Saving linked account(s)...';
      $.ajax({
        url: '/integrations/plaid/link_account',
        type: 'POST',
        data: JSON.stringify({ public_token: publicToken }),
        contentType: 'application/json',
        success: function(resp) {
          var count = resp && resp.linked_count ? resp.linked_count : 0;
          var saved = resp && resp.saved_count ? resp.saved_count : 0;
          data.message = 'Linked ' + count + ' account(s), saved ' + saved + '.';
          load_accounts();
        },
        error: function(xhr) {
          data.message = parse_error(xhr, 'Failed to save linked account');
        }
      });
    },
    onExit: function(err) {
      if (err) {
        data.message = err.display_message || err.error_message || 'Plaid Link exited with an error';
      }
    }
  });

  handler.open();
}

function parse_error(xhr, fallback) {
  try {
    var payload = JSON.parse(xhr.responseText || '{}');
    return payload.error || fallback;
  } catch (e) {
    return fallback;
  }
}

function poll_stripe_pnl_job(jobId, attempts) {
  var maxAttempts = 150;
  var delayMs = 2000;

  if(attempts >= maxAttempts) {
    set_stripe_pnl_generating(false);
    data.message = 'Stripe P&L generation timed out. Try a smaller date range.';
    return;
  }

  setTimeout(function() {
    $.get('/models/staff/stripe_pnl_sheet_status', { job_id: jobId })
      .done(function(resp) {
        if(!resp || !resp.status) {
          poll_stripe_pnl_job(jobId, attempts + 1);
          return;
        }

        if(resp.status === 'completed' && resp.url) {
          set_stripe_pnl_generating(false);
          window.location = resp.url;
          return;
        }

        if(resp.status === 'failed') {
          set_stripe_pnl_generating(false);
          data.message = resp.error || 'Stripe P&L job failed';
          return;
        }

        poll_stripe_pnl_job(jobId, attempts + 1);
      })
      .fail(function() {
        poll_stripe_pnl_job(jobId, attempts + 1);
      });
  }, delayMs);
}

function set_stripe_pnl_generating(isGenerating) {
  data['stripe_pnl_generating'] = !!isGenerating;
  data['stripe_pnl_button_text'] = isGenerating ? 'Generating Stripe P&L…' : 'Generate Stripe P&L Sheet';
}
