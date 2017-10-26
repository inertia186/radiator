require 'bundler/gem_tasks'
require 'rake/testtask'
require 'yard'
require 'radiator'
require 'awesome_print'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.ruby_opts << if ENV['HELL_ENABLED']
    '-W2'
  else
    '-W1'
  end
end

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb']
end

task default: :test

desc 'Deletes test/fixtures/vcr_cassettes/*.yml so they can be rebuilt fresh.'
task :dump_vcr do |t|
  exec 'rm -v test/fixtures/vcr_cassettes/*.yml'
end

desc 'Tests the ability to broadcast live data.  This task broadcasts a claim_reward_balance of 0.0000001 VESTS.'
task :test_live_broadcast, [:account, :wif, :chain] do |t, args|
  account_name = args[:account] || 'social'
  posting_wif = args[:wif] || '5JrvPrQeBBvCRdjv29iDvkwn3EQYZ9jqfAHzrCyUvfbEbRkrYFC'
  chain = args[:chain] || 'steem'
  options = {chain: chain, wif: posting_wif}
  tx = Radiator::Transaction.new(options)
  tx.operations << {
    type: :claim_reward_balance,
    account: account_name,
    reward_steem: '0.000 STEEM',
    reward_sbd: '0.000 SBD',
    reward_vests: '0.000001 VESTS'
  }
  
  response = tx.process(true)
  ap response
  
  if !!response.result
    result = response.result
    
    puts "https://steemd.com/b/#{result[:block_num]}" if !!result[:block_num]
    puts "https://steemd.com/tx/#{result[:id]}" if !!result[:id]
  end
end

desc 'Tests the ability to stream live data.'
task :test_live_stream, :chain do |t, args|
  chain = args[:chain] || 'steem'
  last_block_number = 0
  options = {chain: chain}
  api = Radiator::Api.new(options)
  total_ops = 0.0
  total_vops = 0.0
  
  Radiator::Stream.new(options).blocks do |b, n|
    if last_block_number == 0
      # skip test
    elsif last_block_number + 1 == n
      t = b.transactions
      t_size = t.size
      o = t.map(&:operations)
      op_size = o.map(&:size).reduce(0, :+)
      total_ops += op_size
      api.get_ops_in_block(n, true) do |vops|
        vop_size = vops.size
        total_vops += vop_size
        
        vop_ratio = if total_vops > 0
          total_vops / total_ops
        else
          0
        end
        
        puts "#{n}: #{b.witness}; transactions: #{t_size}; operations: #{op_size}, virtual operations: #{vop_size} (cumulative vop ratio: #{('%.2f' % (vop_ratio * 100))} %)"
      end
    else
      # This should not happen.  If it does, there's likely a bug in Radiator.
      
      puts "Error, last block nunber was #{last_block_number}, did not expect #{n}."
    end
    
    last_block_number = n
  end
end

desc 'Ruby console with radiator already required.'
task :console do
  exec "irb -r radiator -I ./lib"
end

desc 'Build a new version of the radiator gem.'
task :build do
  exec 'gem build radiator.gemspec'
end

desc 'Publish the current version of the radiator gem.'
task :push do
  exec "gem push radiator-#{Radiator::VERSION}.gem"
end

# We're not going to yank on a regular basis, but this is how it's done if you
# really want a task for that for some reason.

# desc 'Yank the current version of the radiator gem.'
# task :yank do
#   exec "gem yank radiator -v #{Radiator::VERSION}"
# end
