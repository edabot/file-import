require 'rspec'
require 'importer.rb'

describe "#check_header" do
  it "file type check" do
    expect do
      check_header(["this", "that", "other"])
    end.to raise_error("incorrect file type")
  end
  it "batch number check" do
    expect do
      check_header(["/*BDI*/", "that", "other"])
    end.to raise_error("missing batch number")
  end
  it "description check" do
    expect do
      check_header(["/*BDI*/", "Batch: 43", "other"])
    end.to raise_error("missing description")
  end
end

describe "#check_entry" do
  it "checks transaction exists" do
    expect do
      check_entry("", {})
    end.to raise_error("Transaction number missing")
  end
  it "checks transaction is a number" do
    expect do
      check_entry("", {'Transaction' => "ABC"})
    end.to raise_error("Transaction is not a number")
  end
  it "checks originator exists" do
    expect do
      check_entry("", {'Transaction' => "123"})
    end.to raise_error("Transaction originator missing")
  end
  it "checks originator format" do
    expect do
      check_entry("", {'Transaction' => "123",
        'Originator' => "123"})
    end.to raise_error("Originator information is not in '12345 / 12345' format")
  end
  it "checks recipient exists" do
    expect do
      check_entry("", {'Transaction' => "123",
        'Originator' => "123 / 123"})
      end.to raise_error("Transaction recipient missing")
  end
  it "checks recipient format" do
    expect do
      check_entry("", {'Transaction' => "123",
        'Originator' => "123 / 123",
        'Recipient' => "123"})
    end.to raise_error("Recipient information is not in '12345 / 12345' format")
  end
  it "checks type exists" do
    expect do
      check_entry("", {'Transaction' => "123",
        'Originator' => "123 / 123",
        'Recipient' => "123 / 123"})
      end.to raise_error("Type of transaction missing")
  end
  it "checks type is Credit or Debit" do
    expect do
      check_entry("", {'Transaction' => "123",
        'Originator' => "123 / 123",
        'Recipient' => "123 / 123",
        'Type' => 'Flubber'})
    end.to raise_error("Transaction type is not Credit or Debit")
  end
  it "amount exists" do
    expect do
      check_entry("", {'Transaction' => "123",
        'Originator' => "123 / 123",
        'Recipient' => "123 / 123",
        'Type' => 'Credit'})
    end.to raise_error("Amount missing")
  end
  it "amount is a number" do
    expect do
      check_entry("", {'Transaction' => "123",
        'Originator' => "123 / 123",
        'Recipient' => "123 / 123",
        'Type' => 'Credit',
        'Amount' => "a"})
    end.to raise_error("Amount is not a number")
  end

end

describe "amount conversion" do
  it "converts Debit correctly" do
    expect(convert_amount("356", "Debit")).to eq(-356)
  end

  it "converts Credit correctly" do
    expect(convert_amount("356", "Credit")).to eq(356)
  end
end
