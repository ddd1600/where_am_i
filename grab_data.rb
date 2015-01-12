require 'socket'
source 'parse_nmea.rb'

attr_reader :nmea_data

class GrabData
  def initialize(ip="192.168.1.160", port=11123)
    s = TCPSocket.new(ip, port)
    s.gets
    @nmea_data = s.gets
    s.close
  end

  def go
    hsh = parse_NMEA(@nmea_data)
    [return_lat(hsh), return_lng(hsh)]
  end

  def return_lat(hsh)
    if hsh[:lat_ref] == "N"
      lat = hsh[:latitude]
    elsif hsh[:lat_ref] == "S"
      lat = hsh[:latitude] * -1.0
    else
      raise "something is wrong with the data received"
    end
    lat
  end

  def return_lng(hsh)
    if hsh[:long_ref] == "E"
      lng = hsh[:longitude]
    elsif hsh[:long_ref] == "W"
      lng = hsh[:longitude] * -1.0
    else
      raise "something is wrong with the data received"
    end
    lng
  end

end
