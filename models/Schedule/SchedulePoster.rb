module SchedulePoster
 
  def generate(starttime)
    schedule = Scheduling.get_all_between(starttime, starttime >> 7)
    image = MiniMagick::Image.open("../../shared/img/background-blu.jpg")
  end

end