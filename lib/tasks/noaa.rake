namespace :noaa do
    desc 'Update forecast from NOAA'
    task update: %w[environment forecasts:get_batch] do
      include ActionView::Helpers::DateHelper
  
      start_time = Time.current
      Rails.logger.info 'Updating NOAA data...'
  
      hydra = Typhoeus::Hydra.new(max_concurrency: @batch.concurrency)
  
      Spot.where.not(noaa_id: nil).each do |spot|
        ApiRequest.new(batch: @batch, requestable: spot, service: Noaa, hydra:, typhoeus_opts: { cookie: "NOAA_session=#{ENV.fetch('NOAA_SESSION_ID', nil)}" }).get
      end
  
      hydra.run
  
      Rails.logger.info "Finished updating NOAA data in #{distance_of_time_in_words_to_now(start_time)}"
    end
  end
  