POS_STDNET_PATH = 'C:\Stdnet.ini'
RGM_STDNET_PATH = 'D:\Stdnet.ini'

# Some helper method
# noinspection RubyResolve
def set_facter(name, value); Facter.add(name) { setcode { value } } end
# noinspection RubyResolve
def get_facter(name); Facter.value(name) end

# Get hostname and ip_address from core facter
hostname = get_facter(:hostname)
ip_address = get_facter(:ipaddress)

# Set facter `machine`
is_pos = hostname.match(/pos([0-9]+)/) != nil
machine = is_pos ? 'POS' :
    if ip_address.match(/(\d+\.){3}199/)
      'BOH-BOX'
    elsif ip_address.match(/(\d+\.){3}200/)
      'RGM-PC'
    else
      'UNIDENTIFIED-MACHINE'
    end
set_facter('machine', machine)

# Read and parse `Stdnet.ini` file
# Regexp pattern --- {1:type} {2:num} {3:status} [C|D]: \\{4:mount_name}\[C|D]
stdnet_path = is_pos ? POS_STDNET_PATH : RGM_STDNET_PATH
stdnet_records = File.exists?(stdnet_path) ? File.readlines(stdnet_path).
    map { |l| l.match(/^\s*(\S+)\s+([0-9]+)\s+(\S+)\s+[C|D]:\s*\\\\(\S+)\\[C|D]\s*$/) }.compact : []

# Get the hostname of mws and parse it
# Set facters `market`, `brand`, `store`
mws_name = is_pos ? stdnet_records.detect { |r| 'MWS' == r[1] }[4] : hostname
mws_name.scan(/SGH([A-Z]{3})([0-9]{3})/) do |market, store|
  set_facter('market', market)
  set_facter('brand', 'KFC')
  set_facter('store', store)
end unless mws_name.nil?

# Set facter `food_to_go`
is_togo = is_pos && (stdnet_records.count { |r| 'POS' == r[1] && hostname == r[4]  } > 1)
set_facter('food_to_go', is_togo)