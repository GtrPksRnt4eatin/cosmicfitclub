module JSONPoster
 
  def JSONPoster::generate(json_file, assets_folder)

    file = File.open "printable/assets/#{assets_folder}/#{json_file}"
    data = JSON.load file

    @@image = MiniMagick::Image.open("printable/assets/#{data['background']}")

    @@image.draw_elements(data["elements"].map{ |x| x.transform_keys(&:to_sym) })

    @@image

  end

end