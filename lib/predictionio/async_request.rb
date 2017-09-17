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
  # This class contains the URI path and query parameters that is consumed by
  # PredictionIO::Connection for asynchronous HTTP requests.
  class AsyncRequest

    # The path portion of the request URI.
    attr_reader :path

    # Query parameters, or form data.
    attr_reader :params

    # Populates the package with request URI path, and optionally query
    # parameters or form data.
    def initialize(path, params = {})
      @params = params
      @path = path
    end

    # Returns an URI path with query parameters encoded for HTTP GET requests.
    def qpath
      "#{@path}?#{URI::encode_www_form(@params)}"
    end
  end
end
