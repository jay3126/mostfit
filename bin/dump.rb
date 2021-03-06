#! /usr/bin/env ruby

# Usage:
# dump.rb path_to_mostfit_installation

require 'yaml'

# use the current working directory if none provided
mostfit_dir = File.expand_path(ARGV[0]) rescue Dir.pwd

config  = YAML.load_file(File.join(mostfit_dir, 'config', 'database.yml'))
db_name = config['production']['database']
password = config['production']['password']
d = DateTime.now
dump_name = "#{File.basename(mostfit_dir)}-dump-#{d.strftime('%F-%H:%M')}.sql"
dump_path = File.join(mostfit_dir, dump_name)

# dump, and compress
fail "Failed to dump" unless system("mysqldump -p#{password} -u root #{db_name} > #{dump_path}")
puts "Compressing ..."
fail "Failed to compress. Do you have bzip2 installed?" unless system("bzip2 #{dump_path}")

dump_path = "#{dump_path}.bz2"

puts "Database dumped at: #{dump_path}"
puts "To load: bin/slurp.rb #{dump_path} [db_name]"
