require 'plaid'
require 'json'
require 'date'
require 'time'
require 'csv'
require 'sinatra/base'

module PlaidIntegration
  def self.environment
    (ENV['PLAID_ENV'] || 'production').downcase
  end

  def self.client
    return @@client if defined?(@@client) && @@client

    configuration = Plaid::Configuration.new
    configuration.server_index = Plaid::Configuration::Environment[environment]
    configuration.api_key['PLAID-CLIENT-ID'] = ENV['PLAID_CLIENT_ID']
    configuration.api_key['PLAID-SECRET'] = ENV['PLAID_SECRET']

    api_client = Plaid::ApiClient.new(configuration)
    @@client = Plaid::PlaidApi.new(api_client)
  end

  def self.setting_key
    'plaid_accounts'
  end

  def self.json_array_like?(value)
    value.is_a?(Array) || value.class.name == 'Sequel::Postgres::JSONArray'
  end

  def self.json_hash_like?(value)
    value.is_a?(Hash) || value.class.name == 'Sequel::Postgres::JSONHash'
  end

  def self.extract_value(source, key)
    return nil if source.nil?

    if source.is_a?(Hash)
      return source[key.to_s] if source.key?(key.to_s)
      return source[key.to_sym] if source.key?(key.to_sym)
    end

    return source.public_send(key) if source.respond_to?(key)

    nil
  end

  def self.string_value(source, key)
    extract_value(source, key).to_s
  end

  def self.array_from(value)
    return value.to_a if json_array_like?(value)
    return [] if value.nil?

    if value.is_a?(String)
      parsed = JSON.parse(value) rescue nil
      return parsed.to_a if json_array_like?(parsed)
      if json_hash_like?(parsed)
        parsed_accounts = parsed['accounts'] || parsed[:accounts]
        return parsed_accounts.to_a if json_array_like?(parsed_accounts)
      end
      return []
    end

    if json_hash_like?(value)
      value_accounts = value['accounts'] || value[:accounts]
      return value_accounts.to_a if json_array_like?(value_accounts)
      return [value]
    end

    []
  end

  def self.normalize_account_record(record)
    parsed = if record.is_a?(String)
      JSON.parse(record) rescue nil
    else
      record
    end

    return nil unless json_hash_like?(parsed)

    normalized = {}
    parsed.each { |key, value| normalized[key.to_s] = value }
    normalized
  rescue
    nil
  end

  def self.stored_accounts
    setting = Setting[setting_key]
    return [] if setting.nil? || setting.val.nil? || setting.val.to_s.strip.empty?

    raw = setting.val
    payload = raw.is_a?(String) ? (JSON.parse(raw) rescue nil) : raw
    return [] if payload.nil?

    if json_array_like?(payload)
      return array_from(payload)
    end

    if json_hash_like?(payload)
      candidate = payload['val'] || payload[:val]
      candidate = payload['accounts'] || payload[:accounts] if candidate.nil?
      return array_from(candidate)
    end

    array_from(payload)
  rescue
    []
  end

  def self.save_accounts(accounts)
    setting = Setting.find_or_create(key: setting_key)
    setting.update(val: accounts.to_json)
  end

  def self.public_accounts
    array_from(stored_accounts).map do |account|
      normalized = normalize_account_record(account)
      next if normalized.nil?

      normalized.reject { |key, _| key.to_s == 'access_token' }
    end.compact
  end

  def self.remove_account(account_id)
    existing = array_from(stored_accounts).map { |row| normalize_account_record(row) }.compact
    kept = existing.reject { |row| row['account_id'].to_s == account_id.to_s }
    removed = existing.length - kept.length
    save_accounts(kept)
    removed
  end

  def self.normalized_stored_accounts
    array_from(stored_accounts).map { |row| normalize_account_record(row) }.compact
  end

  def self.account_by_mask(mask_suffix)
    suffix = mask_suffix.to_s.strip
    return nil if suffix.empty?

    normalized_stored_accounts.find do |account|
      account_mask = account['mask'].to_s
      account_name = account['name'].to_s
      official_name = account['official_name'].to_s
      account_mask.end_with?(suffix) || account_name.include?(suffix) || official_name.include?(suffix)
    end
  end

  def self.transactions_sheet_rows_for_mask(mask_suffix, start_date, end_date)
    account = account_by_mask(mask_suffix)
    return [] if account.nil?

    rows = transactions(
      access_token: account['access_token'],
      start_date: start_date,
      end_date: end_date
    ).select { |row| row[:account_id].to_s == account['account_id'].to_s }

    out = []
    out << ["Plaid Transactions (#{account['institution_name']} #{account['mask']})"]
    out << ['Period', "#{start_date} to #{end_date}"]
    out << []
    out << ['Date', 'Name', 'Merchant', 'Description', 'Amount', 'Currency', 'Category', 'Pending', 'Transaction ID']

    rows.sort_by { |row| row[:date].to_s }.each do |row|
      out << [
        row[:date],
        row[:display_name].to_s.empty? ? row[:name] : row[:display_name],
        row[:merchant_name],
        row[:description],
        row[:amount],
        row[:iso_currency_code] || row[:unofficial_currency_code],
        Array(row[:category]).join(' > '),
        row[:pending] ? 'yes' : 'no',
        row[:id]
      ]
    end

    out
  end

  def self.link_token(user_id:, redirect_uri: nil)
    products = (ENV['PLAID_PRODUCTS'] || 'transactions').split(',').map(&:strip)
    country_codes = (ENV['PLAID_COUNTRY_CODES'] || 'US').split(',').map(&:strip)
    days_requested = (ENV['PLAID_DAYS_REQUESTED'] || '730').to_i
    days_requested = 730 if days_requested <= 0

    request = Plaid::LinkTokenCreateRequest.new(
      user: { client_user_id: user_id.to_s },
      client_name: (ENV['PLAID_CLIENT_NAME'] || 'CosmicFit'),
      products: products,
      country_codes: country_codes,
      language: 'en',
      transactions: {
        days_requested: days_requested
      }
    )

    if redirect_uri && !redirect_uri.to_s.strip.empty?
      request.redirect_uri = redirect_uri
    elsif ENV['PLAID_REDIRECT_URI'] && !ENV['PLAID_REDIRECT_URI'].strip.empty?
      request.redirect_uri = ENV['PLAID_REDIRECT_URI']
    end

    response = client.link_token_create(request)
    response.link_token
  end

  def self.refresh_transactions_for_account_id(account_id)
    account = normalized_stored_accounts.find { |row| row['account_id'].to_s == account_id.to_s }
    return false if account.nil?

    request = Plaid::TransactionsRefreshRequest.new(access_token: account['access_token'])
    client.transactions_refresh(request)
    true
  end

  def self.exchange_public_token(public_token)
    request = Plaid::ItemPublicTokenExchangeRequest.new(public_token: public_token)
    response = client.item_public_token_exchange(request)
    {
      access_token: response.access_token,
      item_id: response.item_id,
      request_id: response.request_id
    }
  end

  def self.link_account(public_token)
    exchange_result = exchange_public_token(public_token)
    access_token = exchange_result[:access_token]
    item_id = exchange_result[:item_id]

    accounts_request = Plaid::AccountsGetRequest.new(access_token: access_token)
    accounts_response = client.accounts_get(accounts_request)

    remote_accounts = nil
    if accounts_response.respond_to?(:to_hash)
      payload_hash = accounts_response.to_hash
      remote_accounts = array_from(payload_hash[:accounts] || payload_hash['accounts'])
    end
    if remote_accounts.nil? || remote_accounts.empty?
      payload_json = JSON.parse(accounts_response.to_json) rescue {}
      remote_accounts = array_from(payload_json['accounts'])
    end
    if remote_accounts.nil? || remote_accounts.empty?
      remote_accounts = array_from(extract_value(accounts_response, :accounts))
    end

    institution_name = lookup_institution_name(access_token)

    existing = array_from(stored_accounts).map { |row| normalize_account_record(row) }.compact
    saved_count = 0

    remote_accounts.each do |remote|
      account_id = string_value(remote, :account_id)
      next if account_id.empty?

      record = {
        'uid' => "#{item_id}:#{account_id}",
        'item_id' => item_id,
        'access_token' => access_token,
        'account_id' => account_id,
        'name' => extract_value(remote, :name),
        'official_name' => extract_value(remote, :official_name),
        'mask' => extract_value(remote, :mask),
        'type' => extract_value(remote, :type),
        'subtype' => extract_value(remote, :subtype),
        'institution_name' => institution_name,
        'added_at' => Time.now.utc.iso8601
      }

      idx = existing.find_index { |row| row['account_id'].to_s == account_id }
      if idx.nil?
        existing << record
      else
        existing[idx] = existing[idx].merge(record)
      end
      saved_count += 1
    end

    save_accounts(existing)
    {
      item_id: item_id,
      linked_count: remote_accounts.length,
      saved_count: saved_count,
      accounts: public_accounts
    }
  end

  def self.lookup_institution_name(access_token)
    item_request = Plaid::ItemGetRequest.new(access_token: access_token)
    item_response = client.item_get(item_request)
    item_payload = JSON.parse(item_response.to_json)
    institution_id = item_payload.dig('item', 'institution_id')
    return '' if institution_id.to_s.strip.empty?

    institution_request = Plaid::InstitutionsGetByIdRequest.new(
      institution_id: institution_id,
      country_codes: ['US']
    )
    institution_response = client.institutions_get_by_id(institution_request)
    institution_payload = JSON.parse(institution_response.to_json)
    institution_payload.dig('institution', 'name').to_s
  rescue
    ''
  end

  def self.transactions(access_token:, start_date:, end_date:, page_size: 200)
    start_date_obj = start_date.is_a?(Date) ? start_date : Date.parse(start_date.to_s)
    end_date_obj = end_date.is_a?(Date) ? end_date : Date.parse(end_date.to_s)
    count = [[page_size.to_i, 500].min, 1].max

    all_transactions = []
    offset = 0

    loop do
      request = Plaid::TransactionsGetRequest.new(
        access_token: access_token,
        start_date: start_date_obj,
        end_date: end_date_obj,
        options: {
          count: count,
          offset: offset
        }
      )

      response = client.transactions_get(request)
      transactions = response.transactions || []

      all_transactions.concat(transactions.map { |transaction| normalize_transaction(transaction) })

      offset += transactions.length
      break if offset >= response.total_transactions.to_i
    end

    all_transactions
  end

  def self.normalize_transaction(transaction)
    payload = if transaction.respond_to?(:to_hash)
      transaction.to_hash
    elsif transaction.is_a?(Hash)
      transaction
    else
      JSON.parse(transaction.to_json) rescue {}
    end

    payment_meta = payload['payment_meta'] || payload[:payment_meta] || {}
    payment_meta_name = if payment_meta.is_a?(Hash)
      payment_meta['payee'] || payment_meta[:payee] ||
      payment_meta['payer'] || payment_meta[:payer] ||
      payment_meta['reference_number'] || payment_meta[:reference_number]
    end

    counterparties = payload['counterparties'] || payload[:counterparties] || []
    counterparty_name = if counterparties.is_a?(Array) && !counterparties.empty?
      first = counterparties.first
      if first.is_a?(Hash)
        first['name'] || first[:name]
      elsif first.respond_to?(:name)
        first.name
      end
    end

    merchant_name = transaction.merchant_name.to_s
    raw_name = transaction.name.to_s
    original_description = (payload['original_description'] || payload[:original_description]).to_s
    unofficial_merchant_name = (payload['unofficial_merchant_name'] || payload[:unofficial_merchant_name]).to_s

    display_name = [merchant_name, unofficial_merchant_name, counterparty_name.to_s, raw_name].find { |v| !v.to_s.strip.empty? }.to_s
    long_description = [
      original_description,
      raw_name,
      merchant_name,
      unofficial_merchant_name,
      payment_meta_name.to_s,
      counterparty_name.to_s
    ].map { |v| v.to_s.strip }.reject(&:empty?).uniq.join(' | ')

    {
      id: transaction.transaction_id,
      account_id: transaction.account_id,
      date: transaction.date,
      name: raw_name,
      merchant_name: merchant_name,
      display_name: display_name,
      description: long_description,
      original_description: original_description,
      unofficial_merchant_name: unofficial_merchant_name,
      amount: transaction.amount,
      iso_currency_code: transaction.iso_currency_code,
      unofficial_currency_code: transaction.unofficial_currency_code,
      category: transaction.category,
      pending: transaction.pending
    }
  end
end

class PlaidRoutes < Sinatra::Base
  before do
    content_type :json unless request.path_info.end_with?('.csv')
  end

  post '/link_token' do
    payload = parse_json_body
    user_id = payload['user_id'] || params['user_id'] || 'cosmicfit-user'
    redirect_uri = payload['redirect_uri'] || params['redirect_uri']

    link_token = PlaidIntegration.link_token(user_id: user_id, redirect_uri: redirect_uri)

    {
      success: true,
      environment: PlaidIntegration.environment,
      link_token: link_token
    }.to_json
  rescue => e
    log_plaid_error('Plaid Link Token Error', e)
    status 500
    { success: false, error: e.message }.to_json
  end

  post '/exchange_public_token' do
    payload = parse_json_body
    public_token = payload['public_token'] || params['public_token']

    if public_token.to_s.strip.empty?
      halt 400, { success: false, error: 'public_token is required' }.to_json
    end

    result = PlaidIntegration.exchange_public_token(public_token)
    {
      success: true,
      item_id: result[:item_id],
      access_token: result[:access_token],
      request_id: result[:request_id]
    }.to_json
  rescue => e
    log_plaid_error('Plaid Public Token Exchange Error', e)
    status 500
    { success: false, error: e.message }.to_json
  end

  post '/link_account' do
    payload = parse_json_body
    public_token = payload['public_token'] || params['public_token']

    if public_token.to_s.strip.empty?
      halt 400, { success: false, error: 'public_token is required' }.to_json
    end

    result = PlaidIntegration.link_account(public_token)
    {
      success: true,
      item_id: result[:item_id],
      linked_count: result[:linked_count],
      saved_count: result[:saved_count],
      accounts: result[:accounts]
    }.to_json
  rescue => e
    log_plaid_error('Plaid Link Account Error', e)
    status 500
    { success: false, error: e.message }.to_json
  end

  get '/accounts' do
    {
      success: true,
      accounts: PlaidIntegration.public_accounts
    }.to_json
  rescue => e
    log_plaid_error('Plaid Accounts List Error', e)
    status 500
    { success: false, error: e.message }.to_json
  end

  post '/remove_account' do
    payload = parse_json_body
    account_id = (payload['account_id'] || params['account_id']).to_s

    if account_id.strip.empty?
      halt 400, { success: false, error: 'account_id is required' }.to_json
    end

    removed = PlaidIntegration.remove_account(account_id)
    {
      success: true,
      removed: removed,
      accounts: PlaidIntegration.public_accounts
    }.to_json
  rescue => e
    log_plaid_error('Plaid Remove Account Error', e)
    status 500
    { success: false, error: e.message }.to_json
  end

  post '/refresh_account' do
    payload = parse_json_body
    account_id = (payload['account_id'] || params['account_id']).to_s

    if account_id.strip.empty?
      halt 400, { success: false, error: 'account_id is required' }.to_json
    end

    ok = PlaidIntegration.refresh_transactions_for_account_id(account_id)
    halt 404, { success: false, error: 'account not found' }.to_json unless ok

    {
      success: true,
      message: 'refresh requested'
    }.to_json
  rescue => e
    log_plaid_error('Plaid Refresh Account Error', e)
    status 500
    { success: false, error: e.message }.to_json
  end

  post '/transactions' do
    payload = parse_json_body

    access_token = payload['access_token'] || params['access_token'] || ENV['PLAID_ACCESS_TOKEN']
    start_date = payload['start_date'] || params['start_date'] || (Date.today << 1).to_s
    end_date = payload['end_date'] || params['end_date'] || Date.today.to_s

    if access_token.to_s.strip.empty?
      halt 400, { success: false, error: 'access_token is required' }.to_json
    end

    rows = PlaidIntegration.transactions(
      access_token: access_token,
      start_date: start_date,
      end_date: end_date
    )

    {
      success: true,
      count: rows.length,
      start_date: start_date,
      end_date: end_date,
      transactions: rows
    }.to_json
  rescue => e
    log_plaid_error('Plaid Transactions Error', e)
    status 500
    { success: false, error: e.message }.to_json
  end

  get '/transactions.csv' do
    account_id = params['account_id'].to_s
    start_date = params['start_date'].to_s.empty? ? (Date.today << 1).to_s : params['start_date'].to_s
    end_date = params['end_date'].to_s.empty? ? Date.today.to_s : params['end_date'].to_s

    accounts = PlaidIntegration.normalized_stored_accounts
    account = accounts.find { |row| row['account_id'].to_s == account_id }
    halt 404, 'Account not found' if account.nil?

    rows = PlaidIntegration.transactions(
      access_token: account['access_token'],
      start_date: start_date,
      end_date: end_date
    ).select { |row| row[:account_id].to_s == account_id }

    csv = CSV.generate do |out|
      out << ['date', 'display_name', 'name', 'merchant_name', 'description', 'original_description', 'unofficial_merchant_name', 'amount', 'currency', 'category', 'pending', 'transaction_id']
      rows.each do |row|
        out << [
          row[:date],
          row[:display_name],
          row[:name],
          row[:merchant_name],
          row[:description],
          row[:original_description],
          row[:unofficial_merchant_name],
          row[:amount],
          row[:iso_currency_code] || row[:unofficial_currency_code],
          Array(row[:category]).join(' > '),
          row[:pending],
          row[:id]
        ]
      end
    end

    filename = "plaid_transactions_#{account_id}_#{start_date}_#{end_date}.csv"
    content_type 'text/csv'
    response['Content-Disposition'] = "attachment; filename=\"#{filename}\""
    csv
  rescue => e
    log_plaid_error('Plaid Transactions CSV Error', e)
    status 500
    content_type :json
    { success: false, error: e.message }.to_json
  end

  private

  def parse_json_body
    body = request.body.read.to_s
    return {} if body.empty?

    JSON.parse(body)
  rescue
    {}
  end

  def log_plaid_error(title, error)
    if defined?(Slack)
      Slack.err(title, error)
    end
  end
end
