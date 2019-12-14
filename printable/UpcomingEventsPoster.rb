

module UpcomingEventsPoster

  def UpcomingEventsPoster::generate()

  	boxsize  = 1000
  	x_start  = 137
  	y_start  = 90
  	x_margin = 137
  	y_margin = 85

  	dimensions = [ [x_start+boxsize+x_margin,y_start], [x_start,y_start+boxsize+y_margin], [x_start+boxsize+x_margin,y_start+boxsize+y_margin], [x_start,y_start+boxsize*2+y_margin*2], [x_start+boxsize+x_margin,y_start+boxsize*2+y_margin*2] ]

    @@image = MiniMagick::Image.open("printable/assets/a4_bg.jpg")

    Event::list_future.each_with_index do |evt,idx|
      @@image.draw_event_bubble(evt[:id], dimensions[idx][0],dimensions[idx][1] , boxsize)
    end

    @@image.bubble_shadow(boxsize,boxsize,x_start,y_start,900*0.008)
    @@image.draw_box(x_start, y_start, boxsize, boxsize, 900*0.1, 900*0.1)
    @@image.draw_logo(200,320,860)
    @@image.draw_highlight_text("Upcoming Events!",26,180,800,"None","\#BBBBFFFF","\#DDDDFFDD",2) # ,fill=Values::RedText,stroke="\#FFFFFFDD",strokewidth=3)
    @@image.draw_footer(17.5)

    @@image

  end

end

