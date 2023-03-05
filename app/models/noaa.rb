class Noaa < Forecast
  class << self
    def base_api_url
      'https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?'
    end
  end
end
