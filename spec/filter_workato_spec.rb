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

  it 'add rails log level' do
    driver.run do
      driver.feed("filter.test", event_time, {
        'message' => "2019-04-12T12:31:46.755428  rails  INFO  Waking up" })
      driver.feed("filter.test", event_time, {
        'message' => "2019-04-12T12:32:56.681887 [PID=1038] rails ERROR  [libr" })
      driver.feed("filter.test", event_time, {
        'message' => "D, [2019-04-12T04:41:13.614930 #1044] DEBUG" })
    end

    expect(result['log_level']).to eq "info"
    expect(driver.filtered_records[1]['log_level']).to eq "error"
    expect(driver.filtered_records[2]['log_level']).to eq "debug"
  end

  it 'remove empty lines in multiline' do
    driver.run do
      driver.feed("filter.test", event_time, {
        'message' => "str1\n\n  str2\n\n   str3\nstr4" })
    end

    expect(result['message']).to eq "str1\n  str2\n   str3\nstr4"
  end

  it 'parses text with spaces' do
    driver.run do
      driver.feed("filter.test", event_time, {
        'kubernetes_pod' => 'workato-jobdispatcher-test-84f4cf49bb-fl5nk',
        'message' => '[2019-04-10T07:04:50.738] [WARN] webapp - Fetching list of users page=15. Attempt 1 failed. error="RequestError: Error: ESOCKETTIMEDOUT" test="My message"' })
    end

    expect(result['error']).to eq({ "value_str" => "_RequestError: Error: ESOCKETTIMEDOUT" })
  end

  it 'pass fluent.* log' do
    driver.run do
      driver.feed("fluent.warn", event_time, {
        'kubernetes_pod' => 'workato-jobdispatcher-test-84f4cf49bb-fl5nk',
        'message' => "failed to flush the buffer. retry_time=10 next_retry_seconds=2019-04-08 18:34:13 +0000 chunk=\"58608d2f638c8a3a7a33587b9283fc65\" error_class=Aws::Firehose::Errors::ValidationException error=\"1 validation error detected: Value 'java.nio.HeapByteBuffer[pos=0 lim=1029188 cap=1029188]' at 'records.36.member.data' failed to satisfy constraint: Member must have length less than or equal to 1024000\"" })
    end

    expect(driver.filtered_records.first.keys.size).to eq 2
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

  it 'shrink message if record more than 1MB' do
    driver.run do
      driver.feed("filter.test", event_time, {
        'kubernetes_pod' => 'workato-jobdispatcher-test-84f4cf49bb-fl5nk',
        'message' => %(INSTRUMENTATION  INFO INSTRUMENTATION UpdateRecipeCursor instrumentation: {"function":"Workato::Runtime::JobDispatcher::UpdateRecipeCursor.run","thread_id":47174614266540,"user_id":38978,"flow_id":802707,"recipe_cursor":{"since":"2015-03-30T19:06:27.000000+00:00","last_id":"0eb786f12ccff900cbe6a9c0f70e5ccc", "next_poll": "is a hash", "digest": 123, "document_id": "is a Float", "next_page": "is a boolean", "after": "is a date" },"cursor_md5":"6bca16f057c0106edebd2575c1ac5c0c", "errors": "is a hash", "tail": "#{'a'*1024*2024}", "tail2": {"tail3": "#{'a'*1024*2024}"}}) })
    end

    expect(result['message'].bytesize).to eq 10003
    expect(result['tail'].bytesize).to eq 1003
    expect(result['oversize']).to eq true
    expect(result['tail2']['tail3'].bytesize).to eq 1003
  end

  context "Request id" do
    context 'key-value log' do
      it 'request id at the end' do
        driver.run do
          driver.feed("filter.test", event_time, {
            'kubernetes_pod' => 'workato-jobdispatcher-test-84f4cf49bb-fl5nk',
            'message' => '2019-07-31T16:45:37.893942 [PID=1009] rails  INFO request_id=35dfbc6c-dde9-43f1-b8c3-a19a54bce192 Started GET "/" for 172.23.0.1 at 2019-07-31T16:45:37.893885'
          })
        end

        expect(result['request_id']).to eq("35dfbc6c-dde9-43f1-b8c3-a19a54bce192")
      end

      it 'request id at the begining' do
        driver.run do
          driver.feed("filter.test", event_time, {
            'kubernetes_pod' => 'workato-jobdispatcher-test-84f4cf49bb-fl5nk',
            'message' => '2019-07-31T16:45:37.893942 [PID=1009] rails  INFO Started GET "/" for 172.23.0.1 at 2019-07-31T16:45:37.893885 request_id=35dfbc6c-dde9-43f1-b8c3-a19a54bce192'
          })
        end

        expect(result['request_id']).to eq("35dfbc6c-dde9-43f1-b8c3-a19a54bce192")
      end
    end

    context 'json log' do
      it 'request id at the end' do
        driver.run do
          driver.feed("filter.test", event_time, {
            'kubernetes_pod' => 'workato-jobdispatcher-test-84f4cf49bb-fl5nk',
            'message' => '2019-08-09T20:18:00.217440 [PID=5033] INSTRUMENTATION  INFO UX_INSTRUMENTATION FlowsController.jobs instrumentation: {"flow_id":"3","jobs_fetch_time":0.009877851989585906,"counters_calculate_time":0.0039647770463489,"jobs_map_time":0.006241467024665326,"elapsed_time":0.02018852799665183} request_id=b8413a16-6342-4671-8706-c658c3a51f3e'
          })
        end

        expect(result['request_id']).to eq("b8413a16-6342-4671-8706-c658c3a51f3e")
      end

      it 'request id at the begining' do
        driver.run do
          driver.feed("filter.test", event_time, {
            'kubernetes_pod' => 'workato-jobdispatcher-test-84f4cf49bb-fl5nk',
            'message' => '2019-08-09T20:18:00.217440 [PID=5033] INSTRUMENTATION  INFO request_id=b8413a16-6342-4671-8706-c658c3a51f3e UX_INSTRUMENTATION FlowsController.jobs instrumentation: {"flow_id":"3","jobs_fetch_time":0.009877851989585906,"counters_calculate_time":0.0039647770463489,"jobs_map_time":0.006241467024665326,"elapsed_time":0.02018852799665183}'
          })
        end

        expect(result['request_id']).to eq("b8413a16-6342-4671-8706-c658c3a51f3e")
        expect(result['flow_id']).to eq('3')
      end
    end
  end
end
