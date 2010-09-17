
Gem::Specification.new do |s|
  s.name                  = 'capistrano-scope'
  s.rubyforge_project     = 'capistrano-scope'
  s.homepage              = 'http://github.com/kirtfitzpatrick/capistrano-scope'
  s.version               = '0.0.8'
  s.summary               = 'Lightweight command line server selection for capistrano.'
  s.description           = 'If puppet were a Cadillac, capistrano-scope would be a bicycle.'

  s.required_ruby_version = '>= 1.8.6'

  s.author                = 'Kirt Fitzpatrick'
  s.email                 = 'kirt.fitzpatrick@akqa.com'

  s.files                 = Dir['README', 'lib/capistrano/scope.rb']
  s.rdoc_options << '--title' << 
      'Capistrano Scope - Lightweight command line server selection.' <<
      '--main' << 'README' << '--line-numbers'
  s.extra_rdoc_files      = Dir['README']

  s.add_dependency('capistrano', '2.5.18')
end
