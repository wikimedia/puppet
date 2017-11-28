require 'spec_helper'

describe 'postgresql::slave', :type => :class do
    let(:params) { {
        :ensure           => 'present',
        :master_server    => 'test',
        :replication_pass => 'pass',
        }
    }
    let(:facts) { { :lsbdistcodename => 'jessie' } }

    context 'ensure present' do
        it { should contain_class('postgresql::server') }
        it do
            should contain_file('/etc/postgresql/9.4/main/postgresql.conf').
                with_ensure('present').
                with_content(/include 'slave.conf'/)
        end
        it { should contain_file('/etc/postgresql/9.4/main/slave.conf').with_ensure('present') }
        it do
            should contain_file('/var/lib/postgresql/9.4/main/recovery.conf').
                with_ensure('present').
                with_content(/host=test user=replication password=pass/)
        end
        it { should contain_exec('pg_basebackup-test').with_command(/-h test -U replication -w/)}
    end
end

describe 'postgresql::slave', :type => :class do
    let(:params) { {
        :ensure           => 'present',
        :master_server    => 'test',
        :replication_pass => 'pass',
        :root_dir         => '/srv/postgres',
        }
    }
    let(:facts) { { :lsbdistcodename => 'jessie' } }

    context 'ensure present' do
        it { should contain_class('postgresql::server') }
        it do
            should contain_file('/etc/postgresql/9.4/main/postgresql.conf').
                with_ensure('present').
                with_content(/include 'slave.conf'/)
        end
        it { should contain_file('/etc/postgresql/9.4/main/slave.conf').with_ensure('present') }
        it do
            should contain_file('/srv/postgres/9.4/main/recovery.conf').
                with_ensure('present').
                with_content(/host=test user=replication password=pass/)
        end
        it { should contain_exec('pg_basebackup-test')
                        .with_command(/-h test -U replication -w/)
                        .with_command(%r{-D \/srv\/postgres\/9\.4\/main})
                        .with_unless('/usr/bin/test -f /srv/postgres/9.4/main/PG_VERSION')
        }
    end
end

describe 'postgresql::slave', :type => :class do
    let(:params) { {
        :ensure           => 'absent',
        :master_server    => 'test',
        :replication_pass => 'pass',
        }
    }
    let(:facts) { { :lsbdistcodename => 'jessie' } }

    context 'ensure absent' do
        it { should contain_class('postgresql::server') }
        it { should contain_file('/etc/postgresql/9.4/main/postgresql.conf').with_ensure('absent') }
        it { should contain_file('/etc/postgresql/9.4/main/slave.conf').with_ensure('absent') }
        it { should contain_file('/var/lib/postgresql/9.4/main/recovery.conf').with_ensure('absent') }
    end
end
