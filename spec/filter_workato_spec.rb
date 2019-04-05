require 'spec_helper'

RSpec.describe Fluent::Plugin::WorkatoFilter do
  let(:config) { '
                 <label @ERROR>
                  <match **>
                    @type stdout
                  </match>
                 </label>
                 ' }
  let(:driver) { Fluent::Test::Driver::Filter.new(described_class).configure(config) }
  let(:result) { driver.filtered_records.first }

  it 'parses rails key=value log' do
    driver.run do
      driver.feed("filter.test", event_time, {
        'kubernetes_pod' => 'workato-jobdispatcher-test-84f4cf49bb-fl5nk',
        'message' => '2019-03-21T08:59:14.326063 [PID=980] INSTRUMENTATION  INFO INSTRUMENTATION Runtime API instrumentation thread_id=46971434455680 function_left=deactivate_flow flow_id=26853 user_id=2555 elapsed_time=0.644356318' })
    end

    expect(driver.filtered_records.size).to eq 1
    expect(result['ns']).to eq 'workato'
    expect(result['proctype']).to eq 'jobdispatcher-test'
    expect(result['message'][0]).to eq '2'
    expect(result['function_left']).to eq 'deactivate_flow'
    expect(result['flow_id']).to eq 26853
    expect(result['user_id']).to eq 2555
    expect(result['elapsed_time']).to eq 0.644356318
    expect(result['thread_id']).to eq 46971434455680
  end

  it 'parses json log' do
    driver.run do
      driver.feed("filter.test", event_time, {
        'kubernetes_pod' => 'workato-jobdispatcher-test-84f4cf49bb-fl5nk',
        'message' => ' 2019-03-21T10:08:12.350861 [PID=1004] rails  INFO  User audit: {"audit":{"event":"recipe_stopped","details":{"force":false,"error":false,"stop_reason":"user","request":{"ip_address":"116.15.79.74","user_agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36"}},"user":{"id":2555,"handle":"jand","email":"jan.donyada@workato.com","name":"Jan Donyada"},"team":{"id":2555,"handle":"jand","email":"jan.donyada@workato.com","name":"Jan Donyada"},"resource":{".type":"Flow","id":26839,"name":"(1/3) Select opportunity to add note"},"timestamp":"2019-03-21 10:08:12 UTC"}}
' })
    end

    expect(result['audit']['resource']['dot_type']).to eq 'Flow'
    expect(result['audit']['resource'].has_key?('.type')).to eq false
    expect(result['audit']['timestamp'].to_json).to eq "\"2019-03-21T10:08:12+00:00\""
  end
end
