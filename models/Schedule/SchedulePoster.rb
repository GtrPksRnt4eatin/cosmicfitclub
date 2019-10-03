require 'date'
require 'mini_magick'

module SchedulePoster
 
  def generate(starttime, high_contrast=false)
  	line_height = 60
  	starttime   = Time.parse(starttime)
    schedule    = Scheduling::get_all_sorted_by_days(starttime, starttime >> 7)

    image       = MiniMagick::Image.open("../shared/img/background-blu.jpg") unless high_contrast
    image       = MiniMagick::Image.open("./white.png")                          if high_contrast

  end

end