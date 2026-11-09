data = {
  accounts: [],
  start_date: '',
  end_date: '',
  message: ''
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
    data.accounts = (resp && resp.accounts) ? resp.accounts : [];
    data.message = data.accounts.length ? '' : 'No linked accounts yet.';
  }).fail(function(xhr) {
    data.message = parse_error(xhr, 'Failed to load linked accounts');
  });
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
