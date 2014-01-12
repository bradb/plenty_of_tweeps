class GeoSearch

  def self.find_nearby_locations(options = {})
    #Return a hash of properties for the geoloc results.
    geoloc_results = []
    loc = geocode_search(options)
    if loc.success
      if loc.zip and loc.precision=="zip"
        #This is a zip code search. Now let's get the city back,province/state and country back.
        #Google doesn't return city name when searching by zip/postalcode so you have to go and get it via lat, longs
        findcity = geocode_from_lat_long :lat => loc.lat, :lng => loc.lng
        if findcity.success
          for geoloc in findcity.all
            break if geoloc.city
          end
          geoloc_results.push(GeoLocation.new  :country_code => geoloc.country_code,
                                               :state_code   => geoloc.state,
                                               :city         => geoloc.city,
                                               :lat          => loc.lat,
                                               :lng          => loc.lng,
                                               :zip          => loc.zip)
        end
      else
        #This is a city search or exact address
        for locspec in loc.all
          if locspec.city and locspec.precision=="city"
            geoloc_results.push(GeoLocation.new  :country_code => locspec.country_code,
                                                 :state_code   => locspec.state,
                                                 :city         => locspec.city,
                                                 :lat          => locspec.lat,
                                                 :lng          => locspec.lng,
                                                 :zip          => locspec.zip)
          end
        end
      end
    end
    return geoloc_results
  end  
  
  def self.geocode_from_lat_long(options = {})
    options[:lat] ||= ""
    options[:lng] ||= ""
    lat = options[:lat]    
    lng = options[:lng]
    return Geokit::Geocoders::MultiGeocoder.reverse_geocode([lat,lng])
  end

  def self.geocode_search(options = {})
    options[:search_text] ||= ""
    options[:country_code] ||= ""
    options[:ip_address] ||= ""
    search_text = options[:search_text]    
    country_code = options[:country_code]
    ip_address = options[:ip_address]
    
    results = Geokit::Geocoders::MultiGeocoder.geocode(search_text,:bias=>country_code)
    found_city_or_zip=false
    for locspec in results.all
      if (locspec.city && locspec.precision=="city") || (locspec.zip && locspec.precision=="zip")
        found_city_or_zip=true
      end
    end
    if !found_city_or_zip
      #Get country code hint
      country_code_hint = Geokit::Geocoders::MultiGeocoder.geocode(ip_address)
      country_code = country_code_hint.country_code
      if country_code.present?
        results = Geokit::Geocoders::MultiGeocoder.geocode(search_text + " " + country_code)
      end
    end
    return results
  end

end

class GeoLocation
  attr_accessor :country_code, :state_code, :city, :lat,:lng, :zip
  
  def initialize(options = {})
    @country_code = options[:country_code]
    @state_code   = options[:state_code]
    @city         = options[:city]
    @lat          = options[:lat]
    @lng          = options[:lng]
    @zip          = options[:zip]
  end
end