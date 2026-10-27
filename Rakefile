desc "Run Ruby Console with DB and Model access"

task :console do
  Dir.chdir('utilities')
  ruby "db_models.rb"
end

task :ssl_local do
  `bundle exec thin start -R config.ru --ssl --ssl-key-file shared/.ssl/server.key --ssl-cert-file shared/.ssl/server.crt`
end

desc 'Generate monthly Stripe P&L Google Sheet. Usage: rake stripe_monthly_pnl[2026,10]'
task :stripe_monthly_pnl, [:year, :month] do |_task, args|
  require_relative './ruby/environment'
  require_relative './integrations/sheets'
  require_relative './integrations/stripe_methods'

  year = (args[:year] || Date.today.year).to_i
  month = (args[:month] || Date.today.month).to_i
  halt_msg = 'Month must be between 1 and 12'
  abort(halt_msg) if month < 1 || month > 12

  url = Sheets::create_monthly_stripe_pnl_sheet(year, month)
  puts("Created: #{url}")
end

def load_task_environment
  return if defined?(Payout)

  require_relative './ruby/environment'
  require_relative './ruby/patches'
  require_relative './integrations/database'
  require_relative './integrations/aws'
  require_relative './integrations/stripe_methods'
  require_relative './integrations/slack'
  require_relative './ruby/shrine'

  Dir[File.join(__dir__, 'models/mixins/*.rb')].each { |file| require file unless /.*Routes.*/ =~ file }
  Dir[File.join(__dir__, 'models/Staff/*.rb')].each { |file| require file unless /.*Routes.*/ =~ file }
end

def payout_connected_account_id(payout)
  return payout.staff.stripe_connect_id if payout.staff && payout.staff.stripe_connect_id
  return 'acct_19PkJECHwAcud5J9' if payout.tag == 'cosmic_classes'
  return 'acct_1N70TxFfb5QzQMoY' if ['loft_classes', 'loft_trainings'].include?(payout.tag)
  nil
end

def payout_category_label(payout)
  return 'Classes' if ['cosmic_classes', 'loft_classes', 'pay_slip'].include?(payout.tag)
  return 'Training' if payout.tag == 'loft_trainings'
  payout.tag.to_s.tr('_', ' ').split.map(&:capitalize).join(' ')
end

def payout_period_label(payout)
  payroll = payout.payroll
  if payroll && payroll.start_date && payroll.end_date
    return "#{payroll.start_date.strftime('%m-%d')} to #{payroll.end_date.strftime('%m-%d')}"
  end
  payout.date ? payout.date.strftime('%m-%d') : nil
end

def payout_description_for(payout, account_id)
  base = [payout_period_label(payout), payout_category_label(payout)].compact.reject(&:empty?).join(' ').strip
  return nil if base.empty?

  recipient_name = StripeMethods::get_account_display_name(account_id).to_s.strip
  return base if recipient_name.empty?
  "#{base} to #{recipient_name}"
end

desc 'Backfill Stripe payout descriptions for a year. Usage: rake backfill_payout_descriptions[2026,false]'
task :backfill_payout_descriptions, [:year, :dry_run] do |_task, args|
  load_task_environment

  year = (args[:year] || Date.today.year).to_i
  dry_run = args[:dry_run].to_s.downcase != 'false'
  start_at = Time.new(year, 1, 1, 0, 0, 0, '+00:00')
  end_at = Time.new(year + 1, 1, 1, 0, 0, 0, '+00:00')

  payouts = Payout.where { date >= start_at }.where { date < end_at }.exclude(stripe_payout_id: nil).all
  puts "Backfill year=#{year} dry_run=#{dry_run} payouts=#{payouts.count}"
  puts "Note: Stripe does not allow updating payout description after creation; this task updates transfer descriptions when available."

  updated = 0
  skipped = 0
  failed = 0

  payouts.each do |payout|
    account_id = payout_connected_account_id(payout)
    if account_id.nil? || account_id.empty?
      skipped += 1
      puts "SKIP payout_id=#{payout.id} stripe_payout_id=#{payout.stripe_payout_id} reason=no_connected_account"
      next
    end

    description = payout_description_for(payout, account_id)
    if description.nil? || description.empty?
      skipped += 1
      puts "SKIP payout_id=#{payout.id} stripe_payout_id=#{payout.stripe_payout_id} reason=no_description"
      next
    end

    puts "#{dry_run ? 'DRY' : 'UPD'} payout_id=#{payout.id} stripe_payout_id=#{payout.stripe_payout_id} desc=\"#{description}\""
    next if dry_run

    transfer_id = payout.stripe_transfer_id.to_s.strip
    if transfer_id.empty?
      skipped += 1
      puts "SKIP payout_id=#{payout.id} stripe_payout_id=#{payout.stripe_payout_id} reason=no_transfer_id"
      next
    end

    begin
      Stripe::Transfer.update(transfer_id, { description: description })
      updated += 1
    rescue => e
      failed += 1
      puts "FAIL payout_id=#{payout.id} stripe_payout_id=#{payout.stripe_payout_id} transfer_id=#{transfer_id} error=#{e.class}: #{e.message}"
    end
  end

  puts "Done updated=#{updated} skipped=#{skipped} failed=#{failed} total=#{payouts.count}"
end
