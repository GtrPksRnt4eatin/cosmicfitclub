require 'postmark'

$postmark_client = Postmark::ApiClient.new(ENV['POSTMARK_KEY'])

module Mail

  def Mail.account_created(recipient, model)
    Mail.send_template( 1250101, recipient, model )
  end

  def Mail.password_reset(recipient, model)
    Mail.send_template( 1229081, recipient, model )
  end

  def Mail.membership_welcome(recipient, model)
    Mail.send_template( 1202161, recipient, model )
  end

  def Mail.package_welcome(recipient, model)
    Mail.send_template( 1202281, recipient, model)
  end

  def Mail.training_welcome(recipient, model)
    Mail.send_template( 1206822, recipient, model)
  end

  def Mail.send_template(template_id, recipient, model)
    $postmark_client.deliver_with_template(
      from: 'Donut <donut@cosmicfitclub.com>',
      to: recipient,
      template_id: template_id,
      template_model: model,
      track_opens: true,
      track_links: 'HtmlAndText'
    )
  end

end