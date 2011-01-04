run 'web' do
  start 'merb -p {{port}}'
  
  variant :port, 8000..8002
end

run 'workers' do
  start 'rake resque:work'
  kill_signal 'USR1'

  variant 'one,to,three' do
    env 'QUEUE' => 'one,two,three'
  end

  variant :foo do
    env 'QUEUE' => 'foo,bar,baz'
  end
end


run :test do
  start 'pwd; echo "start {{foo}}"'
  stop 'pwd; echo "stop {{foo}}"'
  
  variant :foo, %w{one two three}
end
