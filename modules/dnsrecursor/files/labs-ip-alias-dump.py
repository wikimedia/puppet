import yaml
import argparse

from novaclient import client as novaclient

argparser = argparse.ArgumentParser()
argparse.add_argument(
    '--config-file',
    help='Path to config file',
    default='/etc/labs-dns-alias.yaml',
    type=argparse.FileType('r')
)

LUA_LINE_TEMPLATE = 'aliasmapping["{public}"] = "{private}" # {name}\n'

args = argparse.parse_args()
config = yaml.safe_load(args.config_file)

aliases = []
for project in config['projects']:
    client = novaclient.Client(
        "1.1",
        config['username'],
        config['password'],
        project,
        config['api_url']
    )

    for server in client.servers.list():
        serverAddresses = {}
        for address in server.addresses['public']:
            if address['OS-EXT-IPS:type'] == 'floating':
                serverAddresses['public_ip'] = str(address['addr'])
            elif address['OS-EXT-IPS:type'] == 'fixed':
                serverAddresses['private_ip'] = str(address['addr'])
        if 'public_ip' in serverAddresses:
            aliases.append((str(server.name), serverAddresses['public_ip'], serverAddresses['private_ip']))

with open(config['output_path'], 'w') as f:
    f.write("aliasmapping = {}\n")
    for name, public, private in aliases:
        f.write(LUA_LINE_TEMPLATE.format(private=private,public=public,name=name))
    f.write("""
function postresolve (remoteip, domain, qtype, records, origrcode)
    for key,val in ipairs(records)
    do
        if (aliasmapping[val.content] and val.qtype == pdns.A) then
            val.content = aliasmapping[val.content]
            setvariable()
        end
    end
    return origrcode, records
end
""")
