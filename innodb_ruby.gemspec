lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require "innodb/version"

Gem::Specification.new do |s|
  s.name        = 'innodb_ruby'
  s.version     = Innodb::VERSION
  s.date        = Time.now.strftime("%Y-%m-%d")
  s.summary     = 'InnoDB data file parser'
  s.description = 'Library for parsing InnoDB data files in Ruby'
  s.authors     = [ 'Jeremy Cole' ]
  s.email       = 'jeremy@jcole.us'
  s.homepage    = 'http://jcole.us/'
  s.files = [
    'lib/innodb.rb',
    'lib/innodb/cursor.rb',
    'lib/innodb/log.rb',
    'lib/innodb/log_block.rb',
    'lib/innodb/page.rb',
    'lib/innodb/space.rb',
  ]
  s.executables = [
    'innodb_dump_log',
    'innodb_dump_space',
  ]
end
