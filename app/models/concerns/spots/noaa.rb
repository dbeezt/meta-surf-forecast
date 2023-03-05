# frozen_string_literal: true

module Spots
  module Noaa
    extend ActiveSupport::Concern

    class_methods do
      def noaa_url(noaa_id, product)
        "https://tidesandcurrents.noaa.gov/#{product}.html?id=#{noaa_id}"
      end
    end

    included do
      has_many :noaas, dependent: :delete_all

      def noaa_url
        self.class.noaa_url(noaa_id, product)
      end

      def noaa_api_url(properties)
        raise "No NOAA spot associated with #{name} (#{id})" if noaa_id.blank?
        "#{::Noaa.base_api_url}
        station=#{noaa_id}
        &product=#{product}
        &date=latest
        &units=metric
        &time_zone=lst   
        &format=json
        &application=meta-surf-forecast
        #{properties}"
      end
    end
  end
end
