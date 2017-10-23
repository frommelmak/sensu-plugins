#! /usr/bin/env ruby
#
# Check PM2 
#
#
# DESCRIPTION:
#  Check all processes managed by the PM2 process manager are running.
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   all
#
# DEPENDENCIES:
#
# USAGE:
#   ./check-pm2.rb -u <username> [-p <app_name>] [--status | -memory | -cpu ]] -w <seconds> -c <seconds>
#
# EXAMPLE:2
#
#   ./check_pm2.rb -w 1 -c 2 -m 60
#
#   If one process is consuming 60 MB or more then the check throws a warning.
#   If 2 o more process are consuming 60 MB or more, then it throws a critical.
#
# LICENSE: 
# Copyright Marcos Martínez <frommelmak@gmail.com>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#
require 'sensu-plugin/check/cli'
require 'json'

class CheckPM2 < Sensu::Plugin::Check::CLI
  option :critical,
    :description => "Max allowed value to consider critical",
    :short => '-c VALUE',
    :long => '--critical=VALUE',
    :proc => proc {|a| a.to_i },
    :required => true

  option :warning,
    :description => "Max allowed value to consider warning",
    :short => '-w VALUE',
    :long => '--warning=VALUE',
    :proc => proc {|a| a.to_i },
    :required => true

  option :username,
    :description => "The user running pm2",
    :short => '-u USER',
    :long => '--username=USER',
    :required => true,
    :default => 'root'

  option :app_name,
    :description => "The App name to look for. All if not pressent",
    :short => '-p APP_NAME',
    :long => '--process=APP_NAME',
    :required => false,
    :default => 'all'

  option :status,
    :description => "Look for the status to throw alerts\n \
                     \t\t     Available status: online, stopping, stopped, launching, errored, one-launch-status",
    :short => '-s STATUS',
    :long => '--status=STATUS',
    :required => false

  option :memory,
    :description => "Look for the max amount of memory allowed for a process to throw alerts",
    :short => '-m',
    :long => '--memory',
    :required => false

  option :cpu,
    :description => "Look for the % of CPU usage to throw alerts",
    :short => '-l',
    :long => '--load ',
    :required => false


  def run

    json = `pm2 jlist`
    processes_hash = JSON.parse(json)
    n = 0
    app_names = []
    metrics= []
    cpus = []
    mems = []
    limit = config[:status]

    if config[:warning] > config[:critical]
       puts "ERROR: Warning threshold can not be greater than Critical!"
       exit 1
    end

    bad_metric_counter =0
    processes_hash.each do |process|
      if config[:status]
        limit="not #{config[:status]}"
        if config[:status] != process["pm2_env"]["status"]
          bad_metric_counter += 1
        end
      elsif config[:memory]
        limit="memory > #{config[:memory]} MB"
        if process["monit"]["memory"].fdiv(1024*1024).round >= config[:memory].to_i
          bad_metric_counter += 1
        end
      elsif config[:load]
        limit="load > #{config[:cpu]} %"
        if process["monit"]["cpu"] >= config[:load].to_i
          bad_metric_counter += 1
        end

      end
    end
    msg = "There are #{bad_metric_counter} processes in bad status (#{limit})"
    critical msg if bad_metric_counter >= config[:critical]
    warning msg if bad_metric_counter >= config[:warning]
    ok msg
  end
end
