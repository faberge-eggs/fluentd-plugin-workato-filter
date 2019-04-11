require 'fluent/filter'
require_relative 'workato_types'

module Fluent::Plugin
  class WorkatoFilter < Filter
    include WorkatoTypes

    # Register this filter as "passthru"
    Fluent::Plugin.register_filter('workato', self)
    RAILS_FORMAT = /\s([\w]{3,})=(([\w\.\-_\&\=\?\%\/\:]+)\b|"([^"]*)")/
    STOP_KEYS = ['_id', '_index', '_score', '_source', '_type', 'type', 'id', 'time', 'timestamp', 'message']

    # config_param works like other plugins

    def configure(conf)
      super
      # do the usual configuration here
    end

    def start
      super
      # This is the first method to be called when it starts running
      # Use it to allocate resources, etc.
    end

    def shutdown
      super
      # This method is called when Fluentd is shutting down.
      # Use it to free up resources, etc.
    end

    def filter(tag, time, record)
      return record if tag.match?(/fluent/)

      # remove_timestamp(record)

      json = {}
      begin
        m = record['message'].match(/(\{.*\})/)
        raise JSON::ParserError unless m

        json = JSON.parse(m[1])
      rescue JSON::ParserError
        record['message'].scan(RAILS_FORMAT).each do |key, _, value1, value2|
          value = value1 || value2
          json[key] = normalize_base_type(value)
        end
      end

      json.delete_if { |key, _| STOP_KEYS.include?(key) }
      record.merge!(json)

      set_metadata(record)
      normalize_values(record)
      normalize_types(record)

      record
    rescue => e
      # Without this, errors don't display in tests
      puts e.full_message
      raise
    end

    def remove_timestamp(record)
      time = record['message'].match(/^\s*[^\s]+\s+/)
      return unless time

      begin
        DateTime.parse(time[0])
        record['message'].sub!(time[0], '')
      rescue ArgumentError
      end
    end

    def normalize_types(record)
      TYPES.each do |item|
        value = record.dig(*item[:path])

        next unless value
        next if item[:type] == 'Boolean' && (value.is_a?(TrueClass) || value.is_a?(FalseClass))
        next if item[:type] != 'Boolean' && value.is_a?(item[:type])

        *prefix, key = item[:path]
        object = record
        object = record.dig(*prefix) unless prefix.empty?

        # binding.pry if prefix == 'errors'
        case item[:type].to_s
        when 'Hash'
          object[key] = { 'value_str' => '_' + value.to_s }

        when 'String'
          object[key] = value.to_s

        when 'Float'
          begin
            object[key] = Float(value)
          rescue ArgumentError
            object[key] = -1
            object["#{key}_value_str"] = value.to_s
          end

        when 'Boolean'
          object[key] = !!value
          object["#{key}_value_str"] = value.to_s

        when 'DateTime'
          begin
            object[key] = DateTime.parse(value.to_s).iso8601
          rescue ArgumentError
            object[key] = ''
            object["#{key}_value_str"] = value.to_s
          end
        end
      end
    end

    def set_metadata(record)
      return unless record.has_key?('kubernetes_pod')

      pod_parts = record['kubernetes_pod'].split('-')
      return if pod_parts.length < 4

      # Kubernetes namespace
      record['ns'] = pod_parts[0]

      # Service name
      record['proctype'] = pod_parts[1..-3].join('-')
    end

    def normalize_values(record)
      new_values = {}

      record.each do |key, value|
        normalize_values(record[key]) if value.is_a? Hash

        if value.is_a? Array
          value.each do |item|
            normalize_values(item) if item.is_a? Hash
          end
        end

        next unless value.is_a?(String)

        # Remove empty lines
        record.delete(key) && next if value.strip.empty?

        # Convert string to date iso format
        begin
          Float(value)
        rescue ArgumentError
          begin
            new_values[key] = DateTime.parse(value).iso8601 if key != 'message' && is_timestamp?(value)
          rescue ArgumentError
          end
        end

        # Replace .key => dot_key
        if key[0] == '.'
          new_values["dot_#{key[1..-1]}"] = value
          record.delete(key)
        end
      end

      record.merge!(new_values)
    end

    def is_timestamp?(date)
      #2019-04-05 14:52:03

      return false unless /\d\d:\d\d:\d\d/.match?(date)
      /\d{4}[\-\.\/]\d{2}[\-\.\/]\d{2}/.match?(date) || /\d{2}[\-\.\/]\d{2}[\-\.\/]\d{4}/.match?(date)
    end

    def normalize_base_type(value)
      return nil if value == 'nil'

      Float(value)
    rescue ArgumentError
      value
    end
  end
end
