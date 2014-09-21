require 'spec_helper'

describe 'atomic ops' do
  before { load_simple_document }
  before { SimpleDocument.field :field1, :default => 0 }

  let(:doc) { SimpleDocument.create }

  context 'when using queue_atomic' do
    it 'increments' do
      doc.queue_atomic do
        doc.field1 += 1
      end

      doc.save
      doc.reload
      doc.field1.should == 1
    end

    it 'increments' do
      doc.queue_atomic do
        doc.field1 += 3
        doc.field1 += 10
        doc.field1 -= 6
        doc.field1 += 8
      end

      doc.save
      doc.reload
      doc.field1.should == 15
    end
  end

  context 'when using aliases' do
    before { SimpleDocument.field :field1, :as => :f1 }

    it 'aliases' do
      doc.queue_atomic do
        doc.field1 -= 1
      end

      doc.save
      doc.reload
      doc.field1.should == -1
    end
  end

  context 'when using dynamic attributes' do
    before do
      SimpleDocument.send(:include, NoBrainer::Document::DynamicAttributes)
    end

    it 'increments' do
      doc['some_field'] = 0
      doc.save

      doc.queue_atomic do
        doc['some_field'] += 1
      end
      doc.save

      SimpleDocument.raw.first['some_field'].should == 1
    end
  end

  context 'when using arrays' do
    before { SimpleDocument.field :field1, :type => Array, :default => [] }

    it 'appends' do
      doc.queue_atomic do
        doc.field1 << 'foo'
        doc.field1 << 'foo'
      end
      doc.save

      SimpleDocument.raw.first['field1'].should == ['foo', 'foo']
    end
  end

  context 'when using sets' do
    before { SimpleDocument.field :field1, :type => Set, :default => [] }

    it 'adds a new value' do
      doc.queue_atomic do
        doc.field1 << 'foo'
        doc.field1 << 'foo'
      end
      doc.save

      SimpleDocument.raw.first['field1'].should == ['foo']
    end
  end

  context 'atomic block restrictions' do
    context 'when using .save' do
      it 'raises' do
        doc.queue_atomic do
          expect { doc.save }.to raise_error(NoBrainer::Error::AtomicBlock,
            /You may persist documents only outside of queue_atomic blocks/)
        end
      end
    end

    context 'when read/write attributes' do
      it 'raises' do
        other_doc = SimpleDocument.new
        doc.queue_atomic do
          expect { other_doc.attributes }.to raise_error(NoBrainer::Error::AtomicBlock,
            /You may not access other documents within an atomic block/)
          expect { other_doc.field1 }.to raise_error(NoBrainer::Error::AtomicBlock,
            /You may not access other documents within an atomic block/)
          expect { other_doc.field1 = nil }.to raise_error(NoBrainer::Error::AtomicBlock,
            /You may not access other documents within an atomic block/)
        end
      end
    end

    context 'when reading a doc' do
      it 'raises' do
        doc.queue_atomic do
          expect { SimpleDocument.first }.to raise_error(NoBrainer::Error::AtomicBlock,
            /You may not access other documents within an atomic block/)
        end
      end
    end
  end

  context 'when using validators' do
    before { SimpleDocument.field :field1, :type => Integer, :validates => { numericality: true } }

    it 'skip validations on atomic ops' do
      doc.queue_atomic do
        doc.field1 += 10
      end
      doc.save
      doc.reload
      doc.field1.should == 10
    end
  end
end