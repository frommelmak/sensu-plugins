#! /usr/bin/env ruby
#
# Check Etimes Cmd 
#
#
# DESCRIPTION:
#  Check if there are running commands older than the specified time.
#  The commands can be anything matching the provided PATTERN.
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   all
#
# DEPENDENCIES:
#
# EXAMPLES:
#   ./check-cmd-etime.rb -p <pattern> -w <seconds> -c <seconds>
#
# LICENSE: 
# Copyright Marcos Martínez <frommelmak@gmail.com>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#

require 'sensu-plugin/check/cli'

class CheckEtimesCmd < Sensu::Plugin::Check::CLI

  option :critical,
    :short => '-c CRITICAL',
    :long => '--critical CRITICAL',
    :description => "Max execution time for a command maching PATTERN",
    :proc => proc {|a| a.to_i },
    :default => 180 

  option :warning,
    :short => '-w WARNING',
    :long => '--warning WARNING',
    :description => "Max execution time for a command maching PATTERN",
    :proc => proc {|a| a.to_i },
    :default => 120 

  option :pattern,
    :short => '-p PATTERN',
    :long => '--pattern PATTERN',
    :description => "The command pattern to look for",
    :required => true

  def etime_procs(pattern)
    etimes_list = []
    cmds = `ps axwwo etimes,command`
    cmds.each_line do |line|
      if line.match(pattern)
       etimes = line.split(' ')
       t = etimes[0].tr("^0-9", '').to_i
       etimes_list.push(t)
      end
    end
    return etimes_list
  end

  def run
    c_numprocs, w_numprocs = 0, 0
    c_running, w_running = false
    procs = etime_procs(config[:pattern])
    procs.each do |etimes|
      if etimes.to_i > config[:warning] and etimes.to_i < config[:critical]
        w_running = true
        w_numprocs = w_numprocs + 1
      end
      if etimes.to_i > config[:critical]
        c_running = true
        c_numprocs = c_numprocs + 1
      end
    end

    critical "There are #{c_numprocs} #{config[:pattern]} processes older than #{config[:critical]} secs" if c_running
    warning "There are #{w_numprocs} #{config[:pattern]} processes older than #{config[:warning]} secs" if w_running
    ok "There are no #{config[:pattern]} processes older than #{config[:warning]} secs" 

  end
end
