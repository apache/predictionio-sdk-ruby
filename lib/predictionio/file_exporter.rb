module PredictionIO
  # This class contains methods that allow you to export data for import though:
  #
  # $ pio import FILENAME

  class FileExporter

    def initialize(filename)
      @filename = filename
      @file = File.open(@filename, 'w')
    end

    def create_event(event, entity_type, entity_id, optional = {})

      h = optional
      h.key?('eventTime') || h['eventTime'] = DateTime.now.to_s
      h['event'] = event
      h['entityType'] = entity_type
      h['entityId'] = entity_id

      json = h.to_json
      @file.write("#{json}\n")
    end

    def close
      @file.close
    end
  end
end
