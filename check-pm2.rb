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
# EXAMPLES:
#   ./check-pm2.rb -u <username> [-p <app_name>] [--status | -memory | -cpu ]] -w <seconds> -c <seconds>
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
    :required => false,
    :default => 'online'

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
    statuses= []
    cpus = []
    mems = []
    processes_hash.each do |process|
      app_names[n] = process["name"]
      statuses[n] = process["pm2_env"]["status"]
      cpus[n] =  process["monit"]["cpu"]
      mems[n] = process["monit"]["memory"].fdiv(1024*1024).round
      n += 1
    end

    bad_status_counter = 0
    statuses.each do |status|
      if status != config[:status]
         bad_status_counter += 1
      end
    end

    critical "critical" if bad_status_counter > config[:critical]
    warning "warning" if bad_status_counter > config[:warning]
    ok "There are #{bad_status_counter} processes in bad status (desired status: #{config[:status]})" if bad_status_counter < config[:critical]

  end
end