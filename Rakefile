# This rakefile is meant to trigger your local puppet-linter. To take
# advantage of that powerful linter, you must have the puppet and
# puppet-lint gems:
#
#   $ sudo gem install puppet
#   $ sudo gem install puppet-lint
#
# Then run the linter using rake (a ruby build helper):
#
#   $ rake lint
#
# A list of top errors can be obtained using:
#   $ rake lint |rev |cut -d\  -f4- | rev | sort | uniq -c | sort -rn
#
# puppet-lint doc is at https://github.com/rodjek/puppet-lint
#
#
# Another target is spec, which runs unit/integration tests. You will need some
# more gems installed using bundler:
#
#   $ bundle install
#   $ bundle exec rake spec
#

require 'bundler/setup'
require 'rubocop/rake_task'
require 'rake/testtask'

RuboCop::RakeTask.new(:rubocop)

# Only care about color when using a tty.
if Rake.application.tty_output?
    # Since we are going to use puppet internal stuff, we might as
    # well attempt to reuse their colorization utility. Note the utility class
    # is not available in older puppet versions.
    begin
        require'puppet/util/colors'
        include Puppet::Util::Colors
    rescue LoadError
        puts "Cant load puppet/util/colors .. no color for you!"
    end
end

unless respond_to? :console_color
    # Define our own colorization method that simply outputs the message.
    def console_color(_level, message)
        message
    end
end

task :default => [:help]

desc 'Show the help'
task :help do
    puts "Puppet helper for operations/puppet.git

Welcome #{ENV['USER']} to WMFs wonderful rake helper to play with puppet.

---[Command line options]----------------------------------------------
`rake -T` : list available tasks
`rake -P` : shows tasks dependencies

---[Available rake tasks]----------------------------------------------"

    # Show our tasks list.
    system "rake -T"

puts "-----------------------------------------------------------------------"
puts "
Examples:

Validate syntax for all puppet manifests:
  rake validate

Validate manifests/nfs.pp and manifests/apaches.pp
  rake \"validate[manifests/nfs.pp manifests/apaches.pp]\"

Run puppet style checker:
  rake lint
"

end

task :run_puppet_lint do
    system('puppet-lint .')
end

desc 'Run all build/tests commands (CI entry point)'
task test: [:rubocop]

desc "Build documentation"
task :doc do
    doc_cmd = [
        "puppet doc",
        "--mode rdoc",
        "--all",  # build all references
        "--manifestdir manifests",
        "--modulepath modules",
    ].join(' ')
    puts "Running #{doc_cmd}"
    system(doc_cmd)
end

desc "Lint puppet files"
task :lint => :run_puppet_lint

desc "Validate puppet syntax (default: manifests/site.pp)"
task :validate, [:files ] do |_t, args|

    success = true

    if args.files
        puts console_color(:info, "Validating " + args.files.inspect)
        ok = puppet_parser_validate args.files
    else
        ok = puppet_parser_validate 'manifests/site.pp'
        success &&= ok

        Dir.glob("modules/*").each do |dir|
            puts console_color(:info, "Validating manifests in '#{dir}'")
            ok = puppet_parser_validate Dir.glob("#{dir}/**/*.pp")
            success &&= ok
        end
    end

    if success
        puts "[OK] " + console_color(:info,  "files looks fine!")
    else
        raise console_color(:alert, "puppet failed to validate files (exit: #{res.exitstatus}")
    end
end

# Validate manifests passed as an array of filenames.
def puppet_parser_validate(*manifests)
    manifests = manifests.join(' ')
    sh "puppet parser validate #{manifests}"
end


namespace :spec do
    FileList['modules/*/spec'].each do |m|
        module_name = m.match('modules/(.+)/')[1]

        desc "Run spec for module #{module_name}"
        task module_name do
            spec_result = system("cd 'modules/#{module_name}' && rake spec")
            raise "Module #{module_name} failed to pass spec" if !spec_result
        end

        desc "Run 'rake spec' in each module"
        task :all => module_name
    end
end

desc "Run spec tests found in modules"
task :spec do

    # Hold a list of modules not passing tests.
    failed_modules = []
    ignored_modules = ['mysql', 'stdlib']

    # Invoke rake whenever a module has a Rakefile.
    FileList["modules/*/Rakefile"].each do |rakefile|

        module_name = rakefile.match('modules/(.+)/')[1]
        next if ignored_modules.include? module_name

        puts '-' * 80
        puts "Running rspec tests for module #{module_name}"
        puts '-' * 80

        spec_result = 0
        Dir.chdir("modules/#{module_name}") do
            spec_result = system('rake spec')
        end
        if !spec_result
            failed_modules << module_name  # recording
        end
        puts "\n"

    end

    puts '-' * 80
    puts 'Finished running tests for all modules'
    puts '-' * 80

    unless failed_modules.empty?
        puts "\nThe following modules are NOT passing tests:\n"
        puts '- ' + failed_modules * "\n- "
        puts
        raise "Some modules had failures, sorry."
    end
end

desc "Generates ctags"
task :tags do
    puts "Generating ctags file.."
    system('ctags -R .')
    puts "Done"
    puts
    puts "See https://github.com/majutsushi/tagbar/wiki#puppet for vim"
    puts "integration with the vim tagbar plugin."
end

# lint
# amass profit
# donate!
