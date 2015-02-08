require 'parse_nmea'

class WhereAmI
  def self.where_am_i?
    #`gpspipe -n 10 -r > ~/temp.txt`
    lines = File.open("/Users/davidddouglas/Develop/where_am_i/data.txt").read.split("\n")
    has_fix = false
    while has_fix == false
      lines.each do |line|
        $hsh = ParseNmea.parse_NMEA(line)
        has_fix = true if $hsh.keys.include?(:latitude)
      end# of lines
    end# of while has_fix == false
    #File.open("/temp.txt", "w") {|f| f.write("")}
    lat, lng = return_lat($hsh), return_lng($hsh)
   end# of method
   
   def self.return_lat(hsh)
     if hsh[:lat_ref] == "N"
       lat = hsh[:latitude]
     elsif hsh[:lat_ref] == "S"
       lat = hsh[:latitude] * -1.0
     else
       raise "something is wrong with the data received"
     end
     lat
   end

   def self.return_lng(hsh)
     if hsh[:long_ref] == "E"
       lng = hsh[:longitude]
     elsif hsh[:long_ref] == "W"
       lng = hsh[:longitude] * -1.0
     else
       raise "something is wrong with the data received"
     end
     lng
   end
end# of class
