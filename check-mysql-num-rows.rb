#! /usr/bin/env ruby
#
# MySQL check num rows
#
#
# DESCRIPTION:
#  This plugin will check the number of rows in a table
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
#   ./check-mysql-num-rows.rb -u <user> -p <password> -h <hostname> -P <port> -d <database> -t <table> -w <num> -c <num>
#
# LICENSE:
# Copyright 2014 Marcos Martinez  <frommelmak@gmail.com>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'mysql'

class CheckMySQLNumRows < Sensu::Plugin::Check::CLI

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
         :description => "Hostname to login to (localhost by default)",
         :short => '-h HOST',
         :long => '--hostname HOST',
         :default => 'localhost'

  option :port,
         :description => "Port to connect to (3306 by default)",
         :short => '-P PORT',
         :long => '--port PORT',
         :default => "3306"

  option :database,
         :description => "Database to check to",
         :short => '-d DATABASE',
         :long => '--database DATABASE',
         :required => true

  option :table,
         :description => "Table to check to",
         :short => '-t TABLE',
         :long => '--table TABLE',
         :required => true


  option :warn,
         :description => "Number of rows upon which we'll issue a warning",
         :short => '-w NUMBER',
         :long => '--warning NUMBER',
         :default => 100

  option :crit,
         :description => "Number of rows upon which we'll issue an alert",
         :short => '-c NUMBER',
         :long => '--critical NUMBER',
         :default => 128

  def run
    begin
        db = Mysql.real_connect(config[:hostname], config[:user], config[:password], config[:database], config[:port].to_i, config[:socket])
        num_rows = db.
            query("SELECT COUNT(*) AS Rows FROM #{config[:table]}").
            fetch_hash.
            fetch('Rows').
            to_i

        critical "Max rows reached in MySQL table #{num_rows} out of #{config[:crit]}" if num_rows >= config[:crit].to_i
        warning "Max rows reached in MySQL: #{num_rows} out of #{config[:warn]}" if num_rows >= config[:warn].to_i
        ok "Rows are under limit. Current number of rows: #{num_rows}"
    rescue Mysql::Error => e
        critical "MySQL check failed: #{e.error}"
    ensure
        db.close if db
    end
  end

end
