require 'geocoder/lookups/pelias'
require 'geocoder/results/mapzen'

# A custom Geocoder::Lookup class for Mapzen search api.
# https://mapzen.com/documentation/search/search/ for more information
#
# Usage:
#
#   # https://github.com/alexreisner/geocoder/blob/master/lib/geocoder/lookups/base.rb#L45
#   r = Geocoder::Lookup::Mapzen.new
#
#   # For geocoding, takes a search string and retutn a Geocoder::Result object.
#   r.search("Washington", params: {})
#
#   # For reverse geocoding, coordinates (latitude, longitude) and retutn a Geocoder::Result object.
#   r.search([38.9143795889, -77.0364987456], params: {})
#
#   # For autocomplete, takes a search string and retutn an array of strings.
#   r = Geocoder::Lookup::MapzenAutocomplete.new
#   r.search("Washington", params: {})
#
module Geocoder::Lookup
  class Mapzen < Pelias
    # params hash must have symbol keys.
    DEFAULT_PARAMS = {
      # Washington metropolitan area bounding box.
      "boundary.rect.min_lon": -77.9830169678,
      "boundary.rect.max_lon": -76.2341308594,
      "boundary.rect.min_lat": 38.2646020963,
      "boundary.rect.max_lat": 39.7198634855,
      sources: "osm,oa,wof",
      layers: "locality,county,neighbourhood,region",
      size: 1
    }.freeze

    def name
      'Mapzen'
    end

    def endpoint
      configuration[:endpoint] || 'search.mapzen.com'
    end

    def query_url(query)
      query_type = if autocomplete?(query)
                     "autocomplete"
                   elsif query.reverse_geocode?
                     "reverse"
                   else
                     "search"
                   end
      "#{protocol}://#{endpoint}/v1/#{query_type}?" + url_query_string(query)
    end

    def autocomplete?(query)
      query.options[:autocomplete]
    end

    # Return a Geocoder::Result::Mapzen object.
    # https://github.com/alexreisner/geocoder/blob/master/lib/geocoder/lookups/base.rb#L45
    def search(text_or_coordinates, options = {})
      unless text_or_coordinates.is_a?(Geocoder::Query)
        query = Geocoder::Query.new(text_or_coordinates, options)
      end

      if autocomplete?(query)
        data = results(query)
        result = result_class.new(data)
        result.cache_hit = @cache_hit if cache
        result
      else
        super(query).first
      end
    end

    private

    # Convert user's query to params hash for this api. Take Geocoder::Query and return params hash.
    # https://github.com/alexreisner/geocoder/blob/master/lib/geocoder/lookups/pelias.rb#L25
    def query_url_params(query)
      # Create common params. Merge user-specified params hash into default params.
      params = DEFAULT_PARAMS.merge(super)
      params[:api_key] = configuration.api_key

      if query.reverse_geocode?
        # For reverse geocoding api
        params[:'point.lat'] = query.coordinates[0]
        params[:'point.lon'] = query.coordinates[1]
      else
        # For search api and autocomplete api
        params[:text] = query.text
      end

      params
    end

    # Fetch data for the specified Geocoder::Query instance and return results as an array.
    # https://github.com/alexreisner/geocoder/blob/master/lib/geocoder/lookups/pelias.rb#L41
    def results(query)
      if autocomplete?(query)
        # An array of 'label' strings or []
        features = super(query)
        labels = features.map { |feature| feature.dig("properties", "label") }
        labels.map { |label| label.rpartition(", USA")[0] }
      else
        # An array of 'features' hashes or []
        super(query)
      end
    end
  end
end
