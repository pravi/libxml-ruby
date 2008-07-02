require 'rubygems'
require 'date'
require 'rake/gempackagetask'
require 'date'

SO_NAME = "libxml.so"

# ------- Default Package ----------
FILES = FileList[
  'README',
  'LICENSE',
  'CHANGES',
  'bin/*',
  'lib/**/*',
  'ext/**/*',
  'doc/**/*',
  'test/*',
  'work/**/*'
]

# Default GEM Specification
default_spec = Gem::Specification.new do |spec|
  spec.name = "libxml-ruby"
  
  spec.homepage = "http://libxml.rubyforge.org/"
  spec.summary = "Ruby libxml bindings"
  spec.description = <<-EOF
    The Libxml-Ruby project provides Ruby language bindings for the GNOME
    Libxml2 XML toolkit. It is free software, released under the MIT License.
    Libxml-ruby's primary advantage over REXML is performance - if speed 
    is your need, these are good libraries to consider, as demonstrated
    by the informal benchmark below.
  EOF

  # Determine the current version of the software
  spec.version = 
    if File.read('ext/libxml/version.h') =~ /\s*RUBY_LIBXML_VERSION\s*['"](\d.+)['"]/
      CURRENT_VERSION = $1
    else
      CURRENT_VERSION = "0.0.0"
    end
  
  spec.author = "Charlie Savage"
  spec.email = "cfis@savagexi.com"
  spec.platform = Gem::Platform::RUBY
  spec.require_path = "lib" 
  spec.bindir = "bin"
  spec.extensions = ["ext/libxml/extconf.rb"]
  spec.files = FILES.to_a
  spec.test_files = Dir.glob("test/tc_*.rb")
  
  spec.required_ruby_version = '>= 1.8.4'
  spec.date = DateTime.now
  spec.rubyforge_project = 'libxml-ruby'
  
  # rdoc
  spec.has_rdoc = true
  spec.rdoc_options << "--title" << "libxml-ruby"
  # Show source inline with line numbers
  spec.rdoc_options << "--inline-source" << "--line-numbers"
  # Make the readme file the start page for the generated html
  spec.rdoc_options << '--main' << 'README'
  #spec.extra_rdoc_files = ['ext/libxml/*.c',
   #                        'README',
    #                       'LICENSE']

end

# Rake task to build the default package
Rake::GemPackageTask.new(default_spec) do |pkg|
  pkg.need_tar = true
  pkg.need_zip = true
end


# ------- Windows Package ----------
# Windows specification
win_spec = default_spec.clone
win_spec.extensions = []
win_spec.platform = Gem::Platform::CURRENT
win_spec.files += ["lib/#{SO_NAME}"]

desc "Create Windows Gem"
task :create_win32_gem do
  # Copy the win32 extension built by MingW - easier to install
  # since there are no dependencies of msvcr80.dll
  current_dir = File.expand_path(File.dirname(__FILE__))

  libraries = [SO_NAME, 'libxml2-2.dll', 'libiconv-2.dll']

  libraries.each do |file_name|
    source = File.join(current_dir, 'work', 'mingw', file_name)
    target = File.join(current_dir, 'lib', file_name)
    cp(source, target)
  end
  
  # Create the gem, then move it to pkg
  Gem::Builder.new(win_spec).build
  gem_file = "#{win_spec.name}-#{win_spec.version}-#{win_spec.platform}.gem"
  mv(gem_file, "pkg/#{gem_file}")

  # Remove win extension from top level directory  
  libraries.each do |file_name|
    target = File.join(current_dir, 'lib', file_name)
    rm(target)
  end
end

task :package => :create_win32_gem
task :default => :package