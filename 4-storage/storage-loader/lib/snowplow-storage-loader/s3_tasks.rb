# Copyright (c) 2012-2013 SnowPlow Analytics Ltd. All rights reserved.
#
# This program is licensed to you under the Apache License Version 2.0,
# and you may not use this file except in compliance with the Apache License Version 2.0.
# You may obtain a copy of the Apache License Version 2.0 at http://www.apache.org/licenses/LICENSE-2.0.
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the Apache License Version 2.0 is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the Apache License Version 2.0 for the specific language governing permissions and limitations there under.

# Author::    Alex Dean (mailto:support@snowplowanalytics.com)
# Copyright:: Copyright (c) 2012-2013 SnowPlow Analytics Ltd
# License::   Apache License Version 2.0

require 'sluice'

# Ruby module to support the S3-related actions required by
# the Hive-based ETL process.
module SnowPlow
  module StorageLoader
    module S3Tasks

      # Constants for working with S3

      # We ignore the HIVE_DEFAULT_PARTITION path. This is
      # the partition which Hive stores events in if they
      # have no dt (date) stamp. With the CloudFront
      # collector, it's safe for us not to load these files
      # because the only 'events' without a dt stamp are
      # favicon requests, the headers in CloudFront access
      # logs etc - i.e. noise.
      # TODO: revisit this when we are ETLing from other
      # collectors (e.g. clojure-collector). Because there
      # shouldn't be any dt-less rows with other collectors
      IGNORE_EVENTS = "(dt=__HIVE_DEFAULT_PARTITION__)"

      # Downloads the SnowPlow event files from the In
      # Bucket to the local filesystem, ready to be loaded
      # into different storage options.
      #
      # Parameters:
      # +config+:: the hash of configuration options
      def download_events(config)
        puts "Downloading SnowPlow events..."

        s3 = Sluice::Storage::S3::new_fog_s3_from(
          config[:s3][:region],
          config[:aws][:access_key_id],
          config[:aws][:secret_access_key])

        # Get S3 location of In Bucket plus local directory
        in_location = Sluice::Storage::S3::Location.new(config[:s3][:buckets][:in])
        download_dir = config[:download][:folder]

        # Exclude event files which match IGNORE_EVENTS
        event_files = Sluice::Storage::NegativeRegex.new(IGNORE_EVENTS)

        # Download
        Sluice::Storage::S3::download_files(s3, in_location, download_dir, event_files)

      end
      module_function :download_events

      # Moves (archives) the loaded SnowPlow event files to the
      # Archive Bucket.
      #
      # Parameters:
      # +config+:: the hash of configuration options
      def archive_events(config)
        puts 'Archiving SnowPlow events...'

        s3 = Sluice::Storage::S3::new_fog_s3_from(
          config[:s3][:region],
          config[:aws][:access_key_id],
          config[:aws][:secret_access_key])

        # Get S3 locations
        in_location = Sluice::Storage::S3::Location.new(config[:s3][:buckets][:in]);
        archive_location = Sluice::Storage::S3::Location.new(config[:s3][:buckets][:archive]);

        # Move all the files in the In Bucket
        Sluice::Storage::S3::move_files(s3, in_location, archive_location, '.+')

      end
      module_function :archive_events

    end
  end
end