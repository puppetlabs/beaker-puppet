source ENV['GEM_SOURCE'] || "https://rubygems.org"

gemspec



def location_for(place, fake_version = nil)
  if place =~ /^(git:[^#]*)#(.*)/
    [fake_version, { :git => $1, :branch => $2, :require => false }].compact
  elsif place =~ /^file:\/\/(.*)/
    ['>= 0', { :path => File.expand_path($1), :require => false }]
  else
    [place, { :require => false }]
  end
end


group :test do
  gem "beaker", *location_for(ENV['BEAKER_VERSION'] || '~> 3.24')
  gem "beaker-abs", *location_for(ENV['ABS_VERSION'] || '~> 0.4.0')
end


if File.exists? "#{__FILE__}.local"
  eval(File.read("#{__FILE__}.local"), binding)
end
