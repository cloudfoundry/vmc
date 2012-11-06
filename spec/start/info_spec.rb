require File.expand_path("../../helpers", __FILE__)

describe "Start#info" do
  it "orders runtimes by category, status, and series" do
    running(:info, :runtimes => true) do
      does("Getting runtimes")
      %w(java7 java node08 node06 node ruby19 ruby18).each do |runtime|
        outputs(runtime) if client.runtimes.find {|r| r.name == runtime}
      end
    end
  end
end