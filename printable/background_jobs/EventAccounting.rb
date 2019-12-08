require 'sucker_punch'

class EventAccounting
  include SuckerPunch::Job

  def perform(event_id)
    p Event[event_id].accounting_csv
  end

end