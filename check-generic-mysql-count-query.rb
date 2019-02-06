#!/usr/bin/env ruby
#
# Check for sent messages by the desk.admira.com
# ===
#
# This plugin look for the number returned by the the passed "select count(<field>)" query
#
# mmartinez@admira.com 2016
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'mysql'

class CheckGenericCountQuery < Sensu::Plugin::Check::CLI

  option :user,
         :description => "MySQL User",
         :short => '-u USER',
         :long => '--user USER',
         :default => 'root'

  option :password,
         :description => "MySQL Password",
         :short => '-p PASS',
         :long => '--password PASS',
         :required => true

  option :hostname,
         :description => "Hostname to login to",
         :short => '-h HOST',
         :long => '--hostname HOST',
         :default => 'localhost'

  option :port,
         :description => "Port to connect to",
         :short => '-P PORT',
         :long => '--port PORT',
         :default => "3306"

  option :database,
         :description => "Database to connect to",
         :short => '-d DATABASE',
         :long => '--database DATABASE'

  option :query,
         :short => '-q',
         :long => '--query QUERY',
         :description => 'Generic SELECT COUNT(<field>)...'

  option :warn,
         :short => '-w N',
         :long => '--warn N',
         :description => 'Trigger a warning if the number returned by the query is over the specified value',
         :proc => proc {|a| a.to_i },
         :default => 1

  option :crit,
         :short => '-c N',
         :long => '--critical N',
         :description => 'Trigger a critical if the number returned by the query the specified value',
         :proc => proc {|a| a.to_i },
         :default => 2

  def run
    begin
        conn = Mysql.new config[:hostname], config[:user], config[:password], config[:database], config[:port].to_i, config[:socket]
        rs = conn.query config[:query]
        num = rs.fetch_row
        ok "There number of items (#{num[0]}) returned by the query is ok" if num[0].to_i < config[:warn]
        critical "The query returns #{num[0]} which is above the critical threshold defined by the check" if num[0].to_i >= config[:crit]
        warning  "The query returns #{num[0]} which is above the warnign threshold deined by the check " if num[0].to_i > config[:warn]
    rescue Mysql::Error => e
        critical "MySQL check failed: #{e.error}"
    ensure
        conn.close if conn
    end
  end
end
