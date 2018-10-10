platforms = hosts.map{|val| val[:platform]}
skip_test "No arista hosts present" unless platforms.any? { |val| /^eos-/ =~ val }
skip_test 'not testing with puppetserver' unless @options['is_puppetserver']
test_name 'Arista Switch Pre-suite' do
  masters = select_hosts({:roles => ['master', 'compile_master']})

  step 'install Arista Module on masters' do
    masters.each do |node|
      on(node, puppet('module','install','aristanetworks-netdev_stdlib_eos'))
    end
  end
end
