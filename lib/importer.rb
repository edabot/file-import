require 'json'

def convert_amount(string, type)
  number = string.to_i
  number = -number if type == "Debit"
  return number
end

def update_entries(originator, recipient, amount)
  @accounts_hash[originator] = @accounts_hash[originator] || 0
  @accounts_hash[recipient] = @accounts_hash[recipient] || 0

  @accounts_hash[originator] -= amount
  @accounts_hash[recipient] += amount
end

def parse_account(account, amount)
  info = account.split(" / ")
  result = {"routing_number" => info[0],
            "account_number" => info[1],
            "net_transactions" => amount
          }
  return result
end


def check_header(header)
  raise "incorrect file type" unless header[0] == "/*BDI*/"
  if header[1].split(": ").length < 2
    raise "missing batch number"
  end
  if header[2].split(": ").length < 2
    raise "missing description"
  end
end

def process_header(header)
  @result = { 'batch' => header[1].split(" ")[-1],
             'description' => header[2][13..-1],
             "accounts" => []
            }
end

def check_entry(entry, data)
  unless data["Transaction"]
    puts entry
    raise "transaction number missing"
  end
  if data["Transaction"] != data["Transaction"].to_i.to_s
    puts entry
    raise "transaction is not a number"
  end
  unless data["Originator"]
    puts entry
    raise "transaction originator missing"
  end
  unless /^\d+\s\/\s\d+$/ === data["Originator"]
    puts entry
    raise "Originator information is not in '12345 / 12345' format"
  end
  unless data["Recipient"]
    puts entry
    raise "transaction recipient missing"
  end
  unless /\d+\s\/\s\d+/ === data["Recipient"]
    puts entry
    raise "Recipient information is not in '12345 / 12345' format"
  end
  unless data["Type"]
    puts entry
    raise "type of transaction missing"
  end
  unless data["Type"] == "Debit" || data["Type"] == "Credit"
    puts entry
    raise "Transaction type is not Credit or Debit"
  end
  unless data["Amount"]
    puts entry
    raise "amount missing"
  end
  if data["Amount"] != data["Amount"].to_i.to_s
    puts entry
    raise "amount is not a number"
  end
end

def process_entries
  @entries.each do |entry|
    data = {}
    entry.each do |line|
      line = line.split(": ")
      data[line[0]] = line[1]
    end
    check_entry(entry, data)
    amount = convert_amount(data["Amount"], data["Type"])
    update_entries(data["Originator"], data["Recipient"], amount)
  end
end

@accounts_hash = {}
if ARGV[0]
  input = File.read(ARGV[0]).split("==\n")
  header = input[0].split("\n")
  check_header(header)
  process_header(header)
  @entries = input[1..-1].map { |line| line.split("\n") }
  process_entries

  @accounts_hash.each { |account, value| @result["accounts"].push(parse_account(account, value)) }

  $stdout.puts JSON.generate(@result)
end
