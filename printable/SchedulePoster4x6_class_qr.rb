require 'date'
require 'mini_magick'
require 'rqrcode'

module SchedulePoster4x6_class_qr

  # generate a 4x6 printable poster for a class with an embedded QR linking to the class page
  # classdef_id - id of ClassDef
  def SchedulePoster4x6_class_qr::generate(classdef_id, img=nil, lines=nil)

    # base background used by other 4x6 generators (approx 1130x1730)
    @@image = MiniMagick::Image.open("printable/assets/4x6_bg.jpg")

    # draw logo and class image bubble similar to SchedulePoster4x6_class
    @@image.draw_logo(75,50,1050,nil)
    # Only draw the iphone bubble when the class exists and has an image
    if classdef_id
      cls = ClassDef[classdef_id]
      begin
        img_obj = cls && cls.image(:original)
      rescue StandardError => e
        img_obj = nil
      end
      if img_obj && img_obj.respond_to?(:url) && img_obj.url
        @@image.draw_iphone_bubble2(classdef_id, 75, 460, 1050, (1050*1.1).to_i)
      end
    end

    # if a class image is specified or available, open it
    if classdef_id
      cls ||= ClassDef[classdef_id]
      begin
        img_obj = cls && cls.image(:original)
        img_url = img_obj && img_obj.respond_to?(:url) ? img_obj.url : nil
        @@bubble = MiniMagick::Image.open(img_url) if img_url
      rescue StandardError => e
        @@bubble = nil
      end
    else
      @@bubble = MiniMagick::Image.open("printable/assets/#{img}") if img
    end

    # small promotional highlight
    @@image.draw_highlight_text("First Class Free! Come In Today!",18,0,75,{ :gravity => 'South' })

    # Generate QR linking to the public class page and add it as a bubbled image
    begin
      url = "https://cosmicfitclub.com/class/#{classdef_id}"
      @@qrcode = MiniMagick::Image.read RQRCode::QRCode.new(url).as_png.to_blob
      # make it fit with the rest of the poster aesthetics
      @@qrcode.to_bubble(nil)
      # place QR in bottom-right with small margin; compute coordinates from image dims
      qr_w = 240
      qr_h = 240
      margin = 20
      x = @@image.width - qr_w - margin
      y = @@image.height - qr_h - margin
      @@image.overlay(@@qrcode, qr_w, qr_h, x, y)
    rescue StandardError => e
      # QR generation failed; continue without QR
      p "QR generation failed: #{e.message}"
    end

    # footer and finish
    @@image.draw_footer({ :ptsize => 9 })

    @@image
  end

end
