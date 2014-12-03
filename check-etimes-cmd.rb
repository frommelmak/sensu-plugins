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
#   ./check-etimes-cmd.rb -p <pattern> -w <seconds> -c <seconds>
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

  def etime_to_esec(etime)
    m = /(\d+-)?(\d\d:)?(\d\d):(\d\d)/.match(etime)
    (m[1]||0).to_i*86400 + (m[2]||0).to_i*3600 + (m[3]||0).to_i*60 + (m[4]||0).to_i
  end

  def etime_procs(pattern)
    etimes_list = []
    cmds = `ps axwwo etime,command|grep #{config[:pattern]}| grep -v grep |awk '{print $1}'`
    cmds.each_line do |etime|
      secs = etime_to_esec(etime)
      etimes_list.push(secs)
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
