extend Beaker::DSL::InstallUtils::FOSSUtils

test_name "Finalize Host Installation"

step "Verify host times" do
  # Get a rough estimate of clock skew among hosts
  times = []
  hosts.each do |host|
    ruby = ruby_command(host)
    on(host, "#{ruby} -e 'puts Time.now.strftime(\"%Y-%m-%d %T.%L %z\")'") do |result|
      times << result.stdout.chomp
    end
  end
  times.map! do |time|
    (Time.strptime(time, "%Y-%m-%d %T.%L %z").to_f * 1000.0).to_i
  end
  diff = times.max - times.min
  if diff < 60000
    logger.info "Host times vary #{diff} ms"
  else
    logger.warn "Host times vary #{diff} ms, tests may fail"
  end
end

step "Configure gem mirror" do
  configure_gem_mirror(hosts)
end
