require 'net/http'
require 'json'

module UnisenderDna
  class Client
    attr_reader :api_key

    def initialize(api_key)
      @api_key  = api_key
      @url = "https://api.unisender.com/ru/api"
    end

    def translate_params(params)
      params.inject({}) do |iparams, (k, v)|
        if k == :field_names
          v.each_with_index do |name, index|
            iparams["field_names[#{index}]"] = name
          end
        elsif k == :data
          v.each_with_index do |row, index|
            row.each_with_index do |data, data_index|
              iparams["data[#{index}][#{data_index}]"] = data
            end if row
          end
        else
          case v
          when String
            iparams[k.to_s] = v
          when Array
            iparams[k.to_s] = v.map(&:to_s).join(',')
          when Hash
            v.each do |key, value|
              if value.is_a? Hash
                value.each do |v_key, v_value|
                  iparams["#{k}[#{key}][#{v_key}]"] = v_value.to_s
                end
              else
                iparams["#{k}[#{key}]"] = value.to_s
              end
            end
          else
            iparams[k.to_s] = v.to_s
          end
        end
        iparams
      end
    end

    def send_email(params)
      response = get_lists

      Rails.logger.info "--- UnisenderDna: get_lists response = #{response.inspect} ---"
      raise NoMethodError.new("Bad response") if response[:code] == '400'
      list_id = response[:body]['result'].map {|x| x['id']}.first

      uri = URI(@url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      params = translate_params(params).delete_if { |_, v| v.empty? }
      params.merge!({ 'api_key' => api_key, 'list_id' => list_id, 'format' => 'json' })
      response = Net::HTTP.post_form(URI("#{@url}/sendEmail"), params)

      Rails.logger.info "--- UnisenderDna: send_email response = #{response.inspect} ---"

      raise NoMethodError.new("Unknown API method") if response.code == '404'

      begin
        body = JSON.parse(response.body)
      rescue => e
        body = {'status' => e}
      end

      { body: body, code: response.code }
    end

    def get_lists
      uri = URI(@url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      query = "#{uri.path}/getLists?api_key=#{api_key}"

      Rails.logger.info "--- UnisenderDna: query = #{query} ---"
  
      req = Net::HTTP::Post.new("#{query}", initheader = {'Content-Type' =>'application/json'})
      response = http.request(req)

      raise NoMethodError.new("Unknown API method") if response.code == '404'

      begin
        body = JSON.parse(response.body)
      rescue => e
        body = {'status' => e}
      end

      { body: body, code: response.code }
    end
  end
end