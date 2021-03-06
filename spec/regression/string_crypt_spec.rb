require 'rspec'

describe "shared string generated by crypt" do
  subject {
    'abc,def,ghi'.split(',')
  }

  it "works for internally shared strings" do
    expect {
      subject.map { |e| e.crypt("xx")  }
    }.to_not raise_error
  end
end
