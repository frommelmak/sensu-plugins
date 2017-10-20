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

    if config[:status]
      processes_hash.each do |process|
        metrics[n] = process["pm2_env"]["status"]
        limit="status #{config[:status]}"
        n += 1
      end
      bad_metric_counter = 0
      metrics.each do |metric|
        if metric != config[:status]
           bad_metric_counter += 1
        end
      end
      msg = "There are #{bad_metric_counter} processes in bad status (metric: #{limit})"
      critical msg if bad_metric_counter >= config[:critical]
      warning msg if bad_metric_counter >= config[:warning]
      ok msg
    end

    if config[:memory]
      processes_hash.each do |process|
        metrics[n] = process["monit"]["memory"].fdiv(1024*1024).round
        limit="memory"
        n += 1
      end
      bad_metric_counter_c = 0
      bad_metric_counter_w = 0
      metrics.each do |metric|
        if metric > config[:warning].to_i
           puts config[:warning].to_i
           bad_metric_counter_w += 1
        end
        if metric > config[:critical].to_i
           puts config[:critical].to_i
           bad_metric_counter_c += 1
        end
      end
    end

    #app_names[n] = process["name"]
    #cpus[n] =  process["monit"]["cpu"]

    ok = n - (bad_metric_counter_w + bad_metric_counter_c)
    msg = "ok: #{ok}, warning: #{bad_metric_counter_w}, critical: #{bad_metric_counter_c} (metric: #{limit})"
    critical msg if bad_metric_counter_c >= config[:critical]
    warning msg if bad_metric_counter_w >= config[:warning]
    ok msg

  end
end