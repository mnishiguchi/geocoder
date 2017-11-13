require 'geocoder/results/pelias'

module Geocoder::Result
  class Mapzen < Pelias
    # Takes a hash of data from a parsed geocoding service response.
    def initialize(data)
      super(data)
    end

    def address(_format = :full)
      properties["label"]
    end

    def city
      locality
    end

    def coordinates
      geometry["coordinates"]&.reverse
    end

    def country_code
      properties["country_a"]
    end

    def postal_code
      properties["postalcode"]&.to_s
    end

    def province
      state
    end

    def state
      properties["region"]
    end

    def state_code
      properties["region_a"]
    end

    def bounding_box
      bbox = @data.fetch("bbox", {})
      bbox[0], bbox[1], bbox[2], bbox[3] = bbox[1], bbox[0], bbox[3], bbox[2]
    end

    # Define instance methods for some geojson feature properties.
    def self.response_attributes
      %w[
        confidence
        country
        county
        county_gid
        gid
        id
        label
        layer
        locality
        locality_gid
        neighbourhood
        neighbourhood_gid
      ]
    end

    response_attributes.each do |a|
      define_method a do
        properties[a]
      end
    end

    private

    def geometry
      @data.fetch("geometry", {})
    end

    def properties
      @data.fetch("properties", {})
    end
  end
end
