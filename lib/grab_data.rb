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
  
	def latLngToDecimal(coord)
		coord = coord.to_s
		decimal = nil
		negative = (coord.to_i < 0)
		
		# Find parts
		if coord =~ /^-?([0-9]*?)([0-9]{2,2}\.[0-9]*)$/
			deg = $1.to_i # degrees
			min = $2.to_f # minutes & seconds
			
			# Calculate
			decimal = deg + (min / 60)
			if negative
				decimal *= -1
			end
		end
		
		decimal
	end
	
	# Parse a raw NMEA sentence and respond with the data in a hash
	def parse_NMEA(raw)
		data = { :last_nmea => nil }
		if raw.nil?
			return data
		end
		raw.gsub!(/[\n\r]/, "")

		line = raw.split(",");
		if line.size < 1
			return data
		end
		
		# Invalid sentence, does not begin with '$'
		if line[0][0, 1] != "$"
			return data
		end
		
		# Parse sentence
		type = line[0][3, 3]
		line.shift

		if type.nil?
			return data
		end
		
		case type
			when "GGA"
				data[:last_nmea] = type
				data[:time]				= line.shift
				data[:latitude]			= latLngToDecimal(line.shift)
				data[:lat_ref]			= line.shift
				data[:longitude]		= latLngToDecimal(line.shift)
				data[:long_ref]			= line.shift
				data[:quality]			= line.shift
				data[:num_sat]			= line.shift.to_i
				data[:hdop]				= line.shift
				data[:altitude]			= line.shift
				data[:alt_unit]			= line.shift
				data[:height_geoid]		= line.shift
				data[:height_geoid_unit] = line.shift
				data[:last_dgps]		= line.shift
				data[:dgps]				= line.shift
	
			when "RMC"
				data[:last_nmea] = type
				data[:time]			= line.shift
				data[:validity]		= line.shift
				data[:latitude]		= latLngToDecimal(line.shift)
				data[:lat_ref]		= line.shift
				data[:longitude]	= latLngToDecimal(line.shift)
				data[:long_ref]		= line.shift
				data[:speed]		= line.shift
				data[:course]		= line.shift
				data[:date]			= line.shift
				data[:variation]	= line.shift
				data[:var_direction] = line.shift
				
			when "GLL"
				data[:last_nmea] 	= type
				data[:latitude]		= latLngToDecimal(line.shift)
				data[:lat_ref]		= line.shift
				data[:longitude]	= latLngToDecimal(line.shift)
				data[:long_ref]		= line.shift
		  	data[:time]				= line.shift
				
			when "RMA"
				data[:last_nmea] = type
				line.shift # data status
				data[:latitude]		= latLngToDecimal(line.shift)
				data[:lat_ref]		= line.shift
				data[:longitude]	= latLngToDecimal(line.shift)
				data[:long_ref]		= line.shift
		  		line.shift # not used
		  		line.shift # not used
				data[:speed]			= line.shift
				data[:course]			= line.shift
				data[:variation]	= line.shift
				data[:var_direction]	= line.shift
		  	
			when "GSA"
				data[:last_nmea] = type
				data[:mode]						= line.shift
				data[:mode_dimension]	= line.shift
		  	
		  	# Satellite data
		  	data[:satellites] ||= []
		  	12.times do |i|
		  		id = line.shift
		  		
		  		# No satallite ID, clear data for this index
		  		if id.empty?
		  			data[:satellites][i] = {}
		  		
		  		# Add satallite ID
		  		else
			  		data[:satellites][i] ||= {}
			  		data[:satellites][i][:id] = id
		  		end
		  	end
		  	
		  	data[:pdop]			= line.shift
		  	data[:hdop]			= line.shift
		  	data[:vdop]			= line.shift
		  	
			when "GSV"
				data[:last_nmea] 	= type
				data[:msg_count]	= line.shift
				data[:msg_num]		= line.shift
				data[:num_sat]		= line.shift.to_i
				
				# Satellite data
		  		data[:satellites] ||= []
				4.times do |i|
		  			data[:satellites][i] ||= {}
		  		
					data[:satellites][i][:elevation]	= line.shift
					data[:satellites][i][:azimuth]		= line.shift
					data[:satellites][i][:snr]			= line.shift
				end
		  	
		  when "HDT"
				data[:last_nmea] = type
				data[:heading]	= line.shift
				
			when "ZDA"
				data[:last_nmea] = type
				data[:time]	= line.shift
				
				day		= line.shift
				month	= line.shift
				year	= line.shift
				if year.size > 2
					year = [2, 2]
				end
				data[:date] = "#{day}#{month}#{year}"
				
				data[:local_hour_offset]		= line.shift
				data[:local_minute_offset]	= line.shift
		end
		
		# Remove empty data
		data.each_pair do |key, value|
			if value.nil? || (value.is_a?(String) && value.empty?)
				data.delete(key)
			end
		end
		
		data
	end

end
