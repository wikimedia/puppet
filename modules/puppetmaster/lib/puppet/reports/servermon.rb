# Puppet reporter to update servermon database
#
# Based on https://serverfault.com/questions/515455/how-do-i-make-puppet-post-facts-after-run
#
# This report handler uses the puppet config from puppet.conf to get the
# active_record database settings and connect to it and issue commands to update
# it in case the used storeconfigs_backend is puppetdb. This is useful for the
# servermon software (https://github.com/servermon/servermon), at least until it
# is updated to support puppetdb directly. The manual SQL command approach was
# chosen instead of reusing the active record approach supported by the rails
# framework of puppet, since it would not be initialized when
# storeconfig_backend = puppetdb
# NOTE: This is probably quite inefficient, but let's evaluate first
#
# Copyright © 2016 Alexandros Kosiaris and Wikimedia Foundation.
# License http://www.apache.org/licenses/LICENSE-2.0

require 'puppet'
require 'mysql'

Puppet::Reports.register_report(:servermon) do
    desc 'Update facts of a servermon database'

    def process
        # Get our users from the configuration
        dbserver = Puppet[:dbserver]
        dbuser = Puppet[:dbuser]
        dbpassword = Puppet[:dbpassword]
        log_level = Puppet[:log_level]
        begin
            con = Mysql.new dbserver, dbuser, dbpassword, 'puppet'
            con.query('BEGIN')
            # First we try to update the host, if it fails, insert it
            update_host = "UPDATE hosts SET \
            environment = '#{self.environment}', \
            updated_at = '#{self.time}', \
            last_compile = '#{self.time}' \
            WHERE name='#{self.host}'"
            con.query(update_host)
            if con.affected_rows == 0
                insert_host = "INSERT INTO hosts(
                name, environment, last_compile, updated_at, created_at) \
                VALUES('#{self.host}', #{self.environment}', '#{self.time}', '#{self.time}', #{self.time}')"
                con.query(insert_host)
            end
            # Now we know the host is there, get the id
            query = "SELECT id from hosts \
            WHERE name='#{self.host}'"
            rs = con.query(query)
            host_id = rs.fetch_row[0]
            if log_level == 'debug'
                puts "Got host: #{self.host} with id: #{host_id}"
            end

            # if facts file found, read it and update facts for host:
            if File.exists?("#{Puppet[:vardir]}/yaml/facts/#{self.host}.yaml")
                node_facts = YAML.load_file("#{Puppet[:vardir]}/yaml/facts/#{self.host}.yaml")
                # We got a Ruby object, get the values attributes and walk it
                node_facts.values.each do |key, value|
                    # First update the fact_names table, if it fails, insert the
                    # fact name
                    update_fact_name = "UPDATE fact_names SET \
                    updated_at = '#{self.time}' \
                    WHERE name='#{key}'"
                    if log_level == 'debug'
                        puts update_fact_name
                    end
                    con.query(update_fact_name)
                    if con.affected_rows == 0
                        insert_fact_name = "INSERT INTO fact_names(name, updated_at, created_at) \
                        VALUES('#{key}', '#{self.time}', '#{self.time}')"
                        if log_level == 'debug'
                            puts insert_fact_name
                        end
                        con.query(insert_fact_name)
                    end
                    # We now can be sure the fact exists if the code reaches
                    # this point, so just get the id
                    query = "SELECT id from fact_names \
                    WHERE name='#{key}'"
                    rs = con.query(query)
                    fact_id = rs.fetch_row[0]
                    if log_level == 'debug'
                        puts "Got fact: #{key} with id: #{fact_id}"
                    end
                    # Now try to update the fact_value, it is fails, insert it
                    update_fact_value = "UPDATE fact_values SET \
                    updated_at = '#{self.time}', \
                    value = '#{value}' \
                    WHERE fact_name_id=#{fact_id} AND host_id=#{host_id}"
                    if log_level == 'debug'
                        puts(update_fact_value)
                    end
                    con.query(update_fact_value)
                    # rubocop:disable Style/Next
                    if con.affected_rows == 0
                        insert_fact_value = "INSERT INTO fact_values( \
                        value,fact_name_id,host_id,updated_at,created_at) \
                        VALUES('#{value}', #{fact_id}, #{host_id}, '#{self.time}', '#{self.time}')"
                        if log_level == 'debug'
                            puts(insert_fact_value)
                        end
                        con.query(insert_fact_value)
                    end
                    # rubocop:enable Style/Next
                end
            end
            con.query('COMMIT')
        rescue Mysql::Error => e
            puts "Mysql error: #{e.errno}, #{e.error}"
            puts e.errno
            puts e.error
        rescue Exception => e
            puts "Exception caught: #{e.errno}, #{e.error}"
        ensure
            con.close if con
        end
    end
end
