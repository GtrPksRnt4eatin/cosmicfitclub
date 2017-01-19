require 'postmark'

$postmark_client = Postmark::ApiClient.new(ENV['POSTMARK_KEY'])

module Mail

  def Mail.send_membership_welcome(recipient, data)
    $postmark_client.deliver_with_template(
      from: 'Donut <donut@cosmicfitclub.com>',
      to: recipient,
      template_id: 1202161,
      template_model: {
         name:      data[:name],
         plan_name: data[:plan_name],
         login_url: data[:login_url]
      },
      track_opens: true,
      track_links: 'HtmlAndText'
    )
  end

  def Mail.send_password_reset(recipient, data)
    $postmark_client.deliver_with_template(
      from: 'Donut <donut@cosmicfitclub.com>',
      to: recipient,
      template_id: 1229081,
      template_model: {
        name: data[:name],
        action_url: data[:reset_url],
        operating_system: "some OS",
        browser_name: "some Browser",
        support_url: "http://suckmyballs.com"
      },
      track_opens: true,
      track_links: 'HtmlAndText'
    )
  end

end