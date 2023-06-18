
module EventSessionsPoster

  def EventSessionsPoster::generate(event_id)
  	@@event = Event[event_id] or return false
    @@image = MiniMagick::Image.open(@@event.image(:original).url)
    @@image.resize "2550x2550!"
    starty = 900
    ptsize = 16
    @@image.draw_logo(775,100,1000,nil,true)
    @@event.sessions.each_with_index do |sess, i|
      col1 = ( Time.parse(sess.start_time).strftime("%l:%M %p") + " - " + Time.parse(sess.end_time).strftime("%l:%M %p") )
      col2 = sess.title
      col3 = sess.description
      #text_line = col1 + col2 + col3
      line_height = ptsize*300/72
      @@image.draw_box(100, (i*line_height * 2) + starty, 2350, (1.5*line_height), line_height/5, line_height/5 )  
      #@@image.draw_text(text_line, ptsize, 0, (i * line_height * 2) + 0.25*line_height + starty, 'North')
      @@image.draw_text(col1,ptsize,150,(i * line_height * 2) + 0.25*line_height + starty, 'Northwest')
      @@image.draw_text(col2,ptsize,100,(i * line_height * 2) + 0.25*line_height + starty, 'North')
      @@image.draw_text(col3,ptsize,150,(i * line_height * 2) + 0.25*line_height + starty, 'Northeast')
    end
    @@image.draw_footer(18)
  end

end