# ec2id.rb
#
# This fact provides ec2id (old-timey instance id) for instances in labs.
# This is used to set the puppet certname, among other things.

require 'facter'

Facter.add(:labsproject) do
  setcode do
    domain = Facter::Util::Resolution.exec("hostname -d").chomp
    if domain.include? "wmflabs"
      metadata = Facter::Util::Resolution.exec("curl -f http://169.254.169.254/openstack/latest/meta_data.json/ 2> /dev/null").chomp
      metadata[/project-id\":\ \"(.*?)\"/,1]
    else
      ""
    end
  end
end

