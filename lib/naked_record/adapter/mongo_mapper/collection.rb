require 'addressable/uri'
require './lib/naked_record/adapter/orm_namespace'

class NakedRecord::Adapter::MongoMapper::Collection < NakedRecord::Adapter
  include MongoMapper
  include NakedRecord::Adapter::OrmNamespace

  WHITELIST = [:all, :count, :first, :last]

  def initialize
    @orm_classes = [::MongoMapper::Document]
  end

  def handles?(*chain)
    collection_class(chain.first)
  end

  def collection_class(obj)
    return obj if obj.is_a? Class and obj < ::MongoMapper::Document

    if obj.is_a? ::Plucky::Query
      obj.model
    elsif obj.is_a? ::Array
      begin
        obj.proxy_association.klass
      rescue NoMethodError
        nil
      end
    else
      nil
    end

  end

  def display(obj)
    { collection_class(obj).name.tableize => obj.all.map do |a|
      ::Hash[*short_fields.select { |n| a.respond_to? n.to_sym }.map { |n| [n, a.__send__(n.to_sym)] }.flatten].merge(
      {
        :links => [{
          :rel => 'self',
          :href => ['/' , a.class.to_s.underscore, a.id.to_s]
        }]})
      end
    }
  end

  def call_proc(*chain)
    target,method,*remaining = chain

    begin
      super
    rescue NoMethodError
      if /^[[:xdigit:]]+$/ === method
        res = target.find(method)
        raise NakedRecord::RecordNotFound if res.nil?
        {:res => target.find(method), :remaining => remaining}
      else
        raise NoMethodError.new(method)
      end
    end
  end

  def interesting_methods(klass)
    klass = collection_class(klass)
    (klass.public_methods - platonic_class(klass).public_methods).reject { |m| m.to_s.match /^(_|original_)/ } + WHITELIST
  end

end
