require 'humanize'
require 'mini_magick'
require 'rqrcode'

module GiftCert

  def GiftCert::generate(cert_id)
    
    cert = GiftCertificate[cert_id] or return false

    @@image  = MiniMagick::Image.open "printable/assets/gift_cert_bg.jpg"
    @@qrcode = MiniMagick::Image.read RQRCode::QRCode.new("https://cosmicfitclub.com/checkout/redeem_gift/#{cert.code}").as_png.to_blob

    @@image.draw_box(0,0,956,160,0,0,"\#00000055")

    @@image.draw_logo(25,25,325)

    @@image.draw_paragraph("GIFT CERTIFICATE\r\nFOR #{cert.num_passes.humanize.upcase} CLASSES",12,170,30,"north","\#FFFFFFFF",10)
    
    box_starty  = 182
    box_spacing = 90

    @@image.draw_box(406, box_starty, 525, 60, 10, 10,"\#FFFFFFDD")
    @@image.draw_box(406, box_starty + box_spacing, 525, 60, 10, 10,"\#FFFFFFDD")
    @@image.draw_box(406, box_starty + box_spacing*2, 525, 60, 10, 10,"\#FFFFFFDD")

    @@image.draw_paragraph("From:\r\nTo:\r\nFor:",8,570,box_starty+18,"northeast","\#FFFFFFFF",55)
    @@image.draw_paragraph("#{cert.from}\r\n#{cert.to}\r\n#{cert.occasion}",8,425,box_starty+18,"northwest","\#000000FF",55)

    @@qrcode.to_bubble(nil)
    @@image.overlay(@@qrcode, 240, 240, 25,183)
    @@image.draw_text(cert.code,5,-330,397,'north',"\#000000FF")

    @@image.draw_footer(7)

  end

  def GiftCert::generate_black(cert_id)
    cert = GiftCertificate[cert_id] or return false

    @@image  = MiniMagick::Image.open "printable/assets/gift_cert_bg_mono.jpg"
    @@qrcode = MiniMagick::Image.read RQRCode::QRCode.new("https://cosmicfitclub.com/checkout/redeem_gift/#{cert.code}").as_png.to_blob

    @@image.draw_box(0,0,956,160,0,0,"\#FFFFFF55")

    @@image.draw_logo(25,25,325,nil,true)

    @@image.draw_paragraph("GIFT CERTIFICATE\r\nFOR #{cert.num_passes.humanize.upcase} CLASSES",12,170,30,"north","\#000000FF",10)
    
    box_starty  = 182
    box_spacing = 90

    @@image.draw_box(406, box_starty, 525, 60, 10, 10,"\#FFFFFFDD")
    @@image.draw_box(406, box_starty + box_spacing, 525, 60, 10, 10,"\#FFFFFFDD")
    @@image.draw_box(406, box_starty + box_spacing*2, 525, 60, 10, 10,"\#FFFFFFDD")

    @@image.draw_paragraph("From:\r\nTo:\r\nFor:",8,570,box_starty+18,"northeast","\#000000FF",55)
    @@image.draw_paragraph("#{cert.from}\r\n#{cert.to}\r\n#{cert.occasion}",8,425,box_starty+18,"northwest","\#000000FF",55)

    @@qrcode.to_bubble(nil)
    @@image.overlay(@@qrcode, 240, 240, 25,183)
    @@image.draw_text(cert.code,5,-330,397,'north',"\#000000FF")

    @@image.draw_footer(7)
  end

  def GiftCert::generate_tall(cert_id)
    cert = GiftCertificate[cert_id] or return false

    @@image  = MiniMagick::Image.open "printable/assets/1080x1920_bg.jpg"
    @@qrcode = MiniMagick::Image.read RQRCode::QRCode.new("https://cosmicfitclub.com/checkout/redeem_gift/#{cert.code}").as_png.to_blob

    @@image.draw_logo(50,50,980)

    @@image.draw_box({x_offset: 0, y_offset: 430,width: 1080, height: 240})
    @@image.draw_box({x_offset: 0, y_offset: 1430, width: 1080, height: 280})

    @@image.draw_paragraph({ text: "GIFT CERTIFICATE\r\nFOR #{cert.num_passes.humanize.upcase} HOURS", ptsize: 23, x_offset: 0, y_offset:450, gravity: "north",color: "\#FFFFFFFF", spacing: 10})
    
    box_starty  = 1470
    box_spacing = 130

    @@image.draw_box({x_offset: 280, y_offset: box_starty, width: 725, height: 100, x_radius: 10, y_radius: 10, color: "\#FFFFFFDD"})
    @@image.draw_box({x_offset: 280, y_offset: box_starty + box_spacing, width: 725, height: 100, x_radius: 10, y_radius: 10, color: "\#FFFFFFDD"})
    @@image.draw_box({x_offset: 280, y_offset: box_starty + box_spacing*2, width: 725, height: 100, x_radius: 10, y_radius: 10, color: "\#FFFFFFDD"})

    @@image.draw_paragraph({ text: "From:\r\nTo:\r\nFor:", ptsize: 14, x_offset: 840, y_offset: box_starty+18, gravity: "northeast", color: "\#FFFFFFFF", spacing: 62})
    @@image.draw_paragraph({ text: "#{cert.from}\r\n#{cert.to}\r\n#{cert.occasion}", ptsize: 16, x_offset: 300, y_offset: box_starty+18, gravity: "northwest", color: "\#000000FF", spacing: 62})

    @@qrcode.to_bubble(nil)
    @@image.overlay(@@qrcode, 680, 680, 200, 710)
    @@image.draw_text(cert.code,12,0,1320,'north',"\#000000FF")

    @@image.draw_footer({ptsize: 7})
  end

end