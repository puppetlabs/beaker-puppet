test_name 'Finalize Host Installation'

step 'Verify host times' do
  # Get a rough estimate of clock skew among hosts
  times = []
  hosts.each do |host|
    ruby = ruby_command(host)
    on(host, "#{ruby} -e 'puts Time.now.strftime(\"%Y-%m-%d %T.%L %z\")'") do |result|
      times << result.stdout.chomp
    end
  end
  times.map! do |time|
    (Time.strptime(time, '%Y-%m-%d %T.%L %z').to_f * 1000.0).to_i
  end
  diff = times.max - times.min
  if diff < 60_000
    logger.info "Host times vary #{diff} ms"
  else
    logger.warn "Host times vary #{diff} ms, tests may fail"
  end
end

step 'Configure gem mirror' do
  # Skip if RELEASE_STREAM is 'puppet9' and platform is aix or solaris
  release_stream = ENV['RELEASE_STREAM']
  skip_platforms = /aix|solaris/i
  if release_stream == 'puppet9' && hosts.any? { |host| host['platform'] =~ skip_platforms }
    logger.info 'Skipping configure_gem_mirror for puppet9 on aix/solaris, issue with rubygems 4.0'
  else
    configure_gem_mirror(hosts)
  end
end
