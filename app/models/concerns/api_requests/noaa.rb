module ApiRequests
    module Noaa
      extend ActiveSupport::Concern
  
    #   tide / wind / water temperature
      included do
        def parse_noaa
          type = options[:type] || 'wave'
          send("parse_noaa_#{type}")
        end
  
        # {
        #     "t": "2023-03-03 00:00", timestamp
        #     "s": "1.30", speed
        #     "d": "176.00", degree
        #     "dr": "S", direction
        #     "g": "1.50", gust?
        #     "f": "0,0" 
        # },
        def parse_noaa_wind
          response.dig('data').each do |entry|
            next unless (timestamp = entry['t'])
  
            record = service_class.unscoped.find_by(spot: requestable, timestamp: requestable.utc_stamp_to_local(timestamp))
            next unless record
  
            # https://magicseaweed.com/help/forecast-table/wind
            # calculate if on/cross/offshore
            # if gust double actual wind, decrease score by 50%?


            # 1. Check Wind Location to spot
                # Lat/Long of Wind Location compared to Lat/Long of nearest shoreline or e.g. MSW spot?
            # 2. Check Wind Direction is on/cross/offshore
                # Determine range for good/bad winds
                # Alter estimate dependent on distance from spot
            # 3. 
            record.wind_rating = entry['s']
            record.save! if record.wind_rating.present?
          end
        end
  
        # https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?date=today&station=9414290&product=water_temperature&units=metric&application=DataAPI_Sample&format=json&time_zone=lst
        #     "data": [
        # {
        #     "t": "2023-03-05 00:00",
        #     "v": "11.4",
        #     "f": "0,0,0"
        # },
        def parse_noaa_water_temperature
          response.dig('data').each do |entry|
            next unless (timestamp = entry['t'])
  
            record = service_class.unscoped.where(spot: requestable, timestamp: requestable.utc_stamp_to_local(timestamp)).first_or_initialize
            record.api_request = self
            record.min_height = entry.dig('surf', 'min')
            record.max_height = entry.dig('surf', 'max')
            record.swell_rating = entry.dig('surf', 'optimalScore')
            record.save! if record.swell_rating.present?
          end
  
        end
      end
    end



    # https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?date=today&station=9414290&product=predictions&units=metric&application=DataAPI_Sample&format=json&time_zone=lst&datum=MLLW&interval=hilo
    # "predictions": [
    #     {
    #         "t": "2023-03-05 04:02",
    #         "v": "0.715",
    #         "type": "L"
    #     },
    def parse_noaa_tide
        response.dig('predictions').each do |entry|
          next unless (timestamp = entry['t'])

          record = service_class.unscoped.find_by(spot: requestable, timestamp: requestable.utc_stamp_to_local(timestamp))
          next unless record

          record.tide = entry['type']
          record.save! if record.wind_rating.present?
        end
      end
end
  