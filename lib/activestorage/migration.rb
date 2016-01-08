class ActiveRecord::ConnectionAdapters::TableDefinition
  def storage(*args)
    options      = { null: false, default: {}.to_json }.merge!(args.extract_options!)
    column_names = args.presence || [:details]
    column_names.each { |name| column(name, :string, options) }
  end
end
