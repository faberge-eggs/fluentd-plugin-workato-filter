require 'spec_helper'

RSpec.describe Fluent::Plugin::WorkatoFilter do
  let(:config) {
    '<label @ERROR>
       <match **>
         @type stdout
       </match>
      </label>'
  }
  let(:driver) { Fluent::Test::Driver::Filter.new(described_class).configure(config) }
  let(:result) { driver.filtered_records.first }

  it 'fix status field' do
    driver.run do
      driver.feed("filter.test", event_time, {
        'kubernetes_pod' => 'calico-typha-64d4978469-pmvk9',
        'message' => "2019-08-07 20:08:26.269 [INFO][8] sync_server.go 825: Starting to send snapshot to client client=10.111.196.93:17748 connID=0x50 seqNo=0xa1 status=in-sync thread=\"kv-sender\"\n" })
    end

    expect(result['status']).to eq({ value: 'in-sync' })
  end
end
