#! /usr/bin/env ruby
#
#   metrics-numfiles
#
# DESCRIPTION:
#   Get the number of files in a folder using find,
#
# OUTPUT:
#   metric data
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#   metrics-numfiles.rb --dir /var/run/ --extension pid
#
# LICENSE: 
# Copyright Marcos Martínez <frommelmak@gmail.com>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#

require 'socket'
require 'sensu-plugin/metric/cli'

class NumFilesMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :dirpath,
         short: '-d PATH',
         long: '--dir PATH',
         description: 'Absolute path to directory to measure',
         required: true

  option :extension,
         short: '-e EXTENSION',
         long: '--extension EXTENSION',
         description: 'File extension of the files to be counted.',
         required: false 

  option :scheme,
         description: 'Metric naming scheme, text to prepend to metric',
         short: '-s SCHEME',
         long: '--scheme SCHEME',
         required: true,
         default: "#{Socket.gethostname}.numfiles"

  def run
    if config[:extension]
      options = "-name *.#{config[:extension]}"
    end

    cmd ="find #{config[:dirpath]} #{options} -type f|wc -l"
    numfiles = `#{cmd}`

    output "#{config[:scheme]}.#{config[:dirpath]}", numfiles.to_i 

    ok
  end
end
