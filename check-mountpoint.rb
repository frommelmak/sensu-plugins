#! /usr/bin/env ruby
#
#   check-mountpoints
#
# DESCRIPTION:
#   Check if the provided dirpaths are mountpoints of just simple folders
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: pathname
#
# USAGE:
#  ./check-mountpoints -p <path>[,<path>]
#
# NOTES:
#
# LICENSE:
#   Marcos Martínez <frommelmak@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'pathname'

class CheckMountPoints < Sensu::Plugin::Check::CLI

  option :paths,
         description: 'Mountpoint dir patgs to check, comma-separated',
         short: '-p PATHS',
         long: '--path PATHS',
         proc: proc { |a| a.split(',') },
         required: true

  def check_mount_points
    @bad_mp = Array.new
    for path in config[:paths]
      pn = Pathname.new(path)
      mp = pn.mountpoint?()
      if mp == false
        @bad_mp.push(path)
      end
    end
    return mp
  end

  def run
    if !check_mount_points
      critical "Mountpoint(s) #{@bad_mp.join(',')} not mounted!"
    else
      ok 'All paths are mountpoints'
    end
  end
end
