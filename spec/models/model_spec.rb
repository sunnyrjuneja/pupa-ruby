require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Pupa::Model do
  module Music
    class Band
      include Pupa::Model

      self.schema = {
        '$schema' => 'http://json-schema.org/draft-03/schema#',
        'properties' => {
          'links' => {
            'items' => {
              'properties' => {
                'url' => {
                  'type' => 'string',
                  'format' => 'uri',
                },
              },
            },
          },
        },
      }

      attr_accessor :name, :label, :founding_date, :inactive, :label_id, :manager_id, :links
      dump :name, :label, :founding_date, :inactive, :label_id, :manager_id, :links
      foreign_key :label_id, :manager_id
      foreign_object :label
    end
  end

  let :properties do
    {name: 'Moderat', label: {name: 'Mute'}, inactive: false, manager_id: '1', links: [{url: 'http://moderat.fm/'}]}
  end

  let :object do
    Music::Band.new(properties)
  end

  describe '.dump' do
    it 'should add properties' do
      [:_id, :_type, :extras, :name, :label, :founding_date, :inactive, :label_id, :manager_id, :links].each do |property|
        Music::Band.properties.to_a.should include(property)
      end
    end
  end

  describe '.foreign_key' do
    it 'should add foreign keys' do
      Music::Band.foreign_keys.to_a.should == [:label_id, :manager_id]
    end
  end

  describe '.foreign_object' do
    it 'should add foreign objects' do
      Music::Band.foreign_objects.to_a.should == [:label]
    end
  end

  describe '.schema=' do
    let :klass_with_absolute_path do
      Class.new do
        include Pupa::Model
        self.schema = '/path/to/schema.json'
      end
    end

    let :klass_with_relative_path do
      Class.new do
        include Pupa::Model
        self.schema = 'schema'
      end
    end

    it 'should accept a hash' do
      Music::Band.json_schema.should == {
        '$schema' => 'http://json-schema.org/draft-03/schema#',
        'properties' => {
          'links' => {
            'items' => {
              'properties' => {
                'url' => {
                  'type' => 'string',
                  'format' => 'uri',
                },
              },
            },
          },
        },
      }
    end

    it 'should accept an absolute path' do
      File.should_receive(:read).and_return('{}')
      klass_with_absolute_path.json_schema.should == {}
    end

    it 'should accept a relative path' do
      File.should_receive(:read).and_return('{}')
      klass_with_relative_path.json_schema.should == {}
    end
  end

  describe '#initialize' do
    it 'should set the _type' do
      object._type.should == 'music/band'
    end

    it 'should set the _id' do
      object._id.should match(/\A[\da-f]{8}-[\da-f]{4}-[\da-f]{4}-[\da-f]{4}-[\da-f]{12}\z/)
    end

    it 'should set properties' do
      object.name.should == 'Moderat'
      object.label.should == {name: 'Mute'}
      object.inactive.should == false
      object.manager_id.should == '1'
      object.links.should == [{url: 'http://moderat.fm/'}]
    end
  end

  describe '#[]' do
    it 'should get a property' do
      object[:name].should == 'Moderat'
    end

    it 'should raise an error if the class is missing the property' do
      expect{object[:nonexistent]}.to raise_error(Pupa::Errors::MissingAttributeError)
    end
  end

  describe '#[]=' do
    it 'should set a property' do
      object[:name] = 'Apparat'
      object[:name].should == 'Apparat'
    end

    it 'should raise an error if the class is missing the property' do
      expect{object[:nonexistent] = 1}.to raise_error(Pupa::Errors::MissingAttributeError)
    end
  end

  describe '#_id=' do
    it 'should set the _id' do
      object._id = '1'
      object._id.should == '1'
    end

    it 'should coerce the _id to a string' do
      object._id = Moped::BSON::ObjectId.new
      object._id.should be_a(String)
    end
  end

  describe '#links' do
    it 'should symbolize keys' do
      object.extras = {'age' => 10}
      object.extras.should == {age: 10}
    end
  end

  describe '#add_extra' do
    it 'should add an extra property' do
      object.add_extra(:age, 10)
      object.extras.should == {age: 10}
    end
  end

  describe '#fingerprint' do
    it 'should return the fingerprint' do
      object.fingerprint.should == {_type: 'music/band', name: 'Moderat', inactive: false, manager_id: '1', links: [{url: 'http://moderat.fm/'}]}
    end
  end

  describe '#foreign_properties' do
    it 'should return the foreign keys and foreign objects' do
      object.foreign_properties.should == {label: {name: 'Mute'}, manager_id: '1'}
    end
  end

  describe '#validate!' do
    let :klass_without_schema do
      Class.new do
        include Pupa::Model
      end
    end

    it 'should do nothing if the schema is not set' do
      klass_without_schema.new.validate!.should == nil
    end

    it 'should return true if the object is valid' do
      object.validate!.should == true
    end

    it 'should raise an error if the object is invalid' do
      object[:links][0][:url] = 'invalid'
      expect{object.validate!}.to raise_error(JSON::Schema::ValidationError)
    end
  end

  describe '#to_h' do
    it 'should include all properties by default' do
      object.to_h.should == {_id: object._id, _type: 'music/band', name: 'Moderat', label: {name: 'Mute'}, inactive: false, manager_id: '1', links: [{url: 'http://moderat.fm/'}]}
    end

    it 'should exclude foreign objects if persisting' do
      object.to_h(persist: true).should == {_id: object._id, _type: 'music/band', name: 'Moderat', inactive: false, manager_id: '1', links: [{url: 'http://moderat.fm/'}]}
    end

    it 'should not include blank properties' do
      object.to_h.should_not have_key(:founding_date)
    end

    it 'should include false properties' do
      object.to_h.should have_key(:inactive)
    end
  end

  describe '#==' do
    it 'should return true if two objects are equal' do
      object.should == Music::Band.new(properties)
    end

    it 'should return false if two objects are unequal' do
      object.should_not == Music::Band.new(properties.merge(name: 'Apparat'))
    end
  end
end
