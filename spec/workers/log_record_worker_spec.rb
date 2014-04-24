require 'spec_helper'

describe LogRecordWorker do
 describe "#perform" do
   it "updates an existing, active LogRecord by jid" do
     data = {
       links_created: 10,
       transition:    "ChildWorker"
     }
     data_complete = data.merge(complete: true)
     attrs = {
       jid:      "abc123",
       data:     data,
       agent:    "Worker",
       archived: false
     }

     LogRecord.create(attrs)
     LogRecordWorker.new.perform(attrs.merge(data: data_complete))
     lr = LogRecord.find_by_jid("abc123")
     expect(lr.data["links_created"]).to eq(20)
     expect(lr.data["complete"]).to be_true
   end

   it "creates a new LogRecord if no log record exists for jid" do
     data = {
       links_created: 10,
       transition:    "ChildWorker"
     }
     attrs = {
       jid:      "abc123",
       data:     data,
       agent:    "Worker",
       archived: false
     }
     LogRecordWorker.new.perform(attrs)
     lr = LogRecord.find_by_jid("abc123")
     expect(lr.data["links_created"]).to eq(10)
   end

   it "updates and unarchives an archived LogRecord" do
     data = {
       links_created: 10,
       transition:    "ChildWorker"
     }
     attrs = {
       jid:      "abc123",
       data:     data,
       agent:    "Worker",
       archived: true
     }

     LogRecord.create(attrs)
     LogRecordWorker.new.perform(attrs.merge(archived: false))
     lr = LogRecord.find_by_jid("abc123")
     expect(lr.data["links_created"]).to eq(20)
     expect(lr.archived).to be_false
   end
 end
end
