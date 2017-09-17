# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
