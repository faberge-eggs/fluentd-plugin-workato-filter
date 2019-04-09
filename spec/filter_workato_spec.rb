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

  it 'pass fluent.* log' do
    driver.run do
      driver.feed("filter.test", event_time, {
        'kubernetes_pod' => 'workato-jobdispatcher-test-84f4cf49bb-fl5nk',
        'tag' => 'fluent.warn',
        'message' => "failed to flush the buffer. retry_time=10 next_retry_seconds=2019-04-08 18:34:13 +0000 chunk=\"58608d2f638c8a3a7a33587b9283fc65\" error_class=Aws::Firehose::Errors::ValidationException error=\"1 validation error detected: Value 'java.nio.HeapByteBuffer[pos=0 lim=1029188 cap=1029188]' at 'records.36.member.data' failed to satisfy constraint: Member must have length less than or equal to 1024000\"" })
    end

    expect(driver.filtered_records.first.keys.size).to eq 3
  end

  it 'returns record if STOP_KEYS' do
    driver.run do
      driver.feed("filter.test", event_time, {
        'kubernetes_pod' => 'workato-jobdispatcher-test-84f4cf49bb-fl5nk',
        'message' => '2019-03-21T08:59:14.326063 [PID=980] INSTRUMENTATION  INFO INSTRUMENTATION Runtime API instrumentation thread_id=46971434455680 function_left=deactivate_flow flow_id=26853 user_id=2555 elapsed_time=0.644356318 timestamp=1' })
    end

    expect(driver.filtered_records.size).to eq 1
    expect(result.has_key? 'timestamp').to eq false
  end

  it 'parses rails key=value log' do
    driver.run do
      driver.feed("filter.test", event_time, {
        'kubernetes_pod' => 'workato-jobdispatcher-test-84f4cf49bb-fl5nk',
        'message' => '2019-03-21T08:59:14.326063 [PID=980] INSTRUMENTATION  INFO INSTRUMENTATION Runtime API instrumentation thread_id=46971434455680 function_left=deactivate_flow flow_id=26853 user_id=2555 elapsed_time=0.644356318' })
    end

    expect(driver.filtered_records.size).to eq 1
    expect(result['ns']).to eq 'workato'
    expect(result['proctype']).to eq 'jobdispatcher-test'
    expect(result['message'][0]).to eq '['
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
        'message' => ' 2019-03-21T10:08:12.350861 [PID=1004] rails  INFO  User audit: {"audit":{"event":"recipe_stopped","details":{"force":false,"error":false,"stop_reason":"user","request":{"ip_address":"116.15.79.74","user_agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36"}},"user":{"id":2555,"handle":"jand","email":"jan.donyada@workato.com","name":"Jan Donyada"},"team":{"id":2555,"handle":"jand","email":"jan.donyada@workato.com","name":"Jan Donyada"},"resource":{".type":"Flow","id":26839,"name":"(1/3) Select opportunity to add note"},"timestamp":"2019-03-21 10:08:12 UTC"}}' })
    end

    expect(result['audit']['resource']['dot_type']).to eq 'Flow'
    expect(result['audit']['resource'].has_key?('.type')).to eq false
    expect(result['audit']['timestamp'].to_json).to eq "\"2019-03-21T10:08:12+00:00\""
  end

  it 'normalize types' do
    driver.run do
      driver.feed("filter.test", event_time, {
        'kubernetes_pod' => 'workato-jobdispatcher-test-84f4cf49bb-fl5nk',
        'message' => 'INSTRUMENTATION  INFO INSTRUMENTATION UpdateRecipeCursor instrumentation: {"function":"Workato::Runtime::JobDispatcher::UpdateRecipeCursor.run","thread_id":47174614266540,"user_id":38978,"flow_id":802707,"recipe_cursor":{"since":"2015-03-30T19:06:27.000000+00:00","last_id":"0eb786f12ccff900cbe6a9c0f70e5ccc", "next_poll": "is a hash", "digest": 123, "document_id": "is a Float", "next_page": "is a boolean", "after": "is a date" },"cursor_md5":"6bca16f057c0106edebd2575c1ac5c0c", "errors": "is a hash"}' })
    end

    expect(result['recipe_cursor']['next_poll']).to eq({ "value_str" => "_is a hash" })
    expect(result['recipe_cursor']['digest']).to eq "123"
    expect(result['recipe_cursor']['document_id']).to eq -1
    expect(result['recipe_cursor']['document_id_value_str']).to eq "is a Float"
    expect(result['recipe_cursor']['next_page']).to eq true
    expect(result['recipe_cursor']['next_page_value_str']).to eq "is a boolean"
    expect(result['recipe_cursor']['after']).to eq ''
    expect(result['recipe_cursor']['after_value_str']).to eq 'is a date'
    expect(result['errors']).to eq({ "value_str" => "_is a hash" })
  end
end
