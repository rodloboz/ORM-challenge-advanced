require 'byebug'

class Record
  include Comparable

  def initialize(attributes = {})
    initialize_accessors
    assign_attributes(attributes)
  end

  def self.attr_accessor(*vars)
    # @attribute_names ||= []
    # @attribute_names.concat vars
    super(*vars)
  end

  # Class Methods:
  class << self
    def attribute_names
      table_columns
    end

    def create(attributes = {})
      new(attributes).save
    end

    # Read
    def find(id)
      result = DB.execute("SELECT * FROM #{table_name} WHERE id = ?", id).first
      result.nil? ? nil : build_record(result)
    end

    def all
      rows = DB.execute("SELECT * FROM #{table_name}")

      return [] if rows.empty?

      rows.map { |row| build_record(row) }
    end

    def last
      all.last
    end

    def first
      all.first
    end

    def second
      all[1]
    end

    def third
      all[2]
    end

    def count
      DB.execute("SELECT COUNT(id) FROM #{table_name}")
        .first["COUNT(id)"]
    end

    # Destroy
    def destroy_all
      DB.execute("DELETE FROM #{table_name}")
      nil
    end

    def where(opts = {})
      key = opts.keys.first
      value = opts.values.first
      DB.execute("SELECT * FROM #{table_name} WHERE #{key} = ?", value)
        .map { |result| build_record(result) }
    end

    private

    def build_record(row)
      new(row.transform_keys!(&:to_sym))
    end

    def table_columns
      DB.execute("PRAGMA table_info(#{table_name})").map { |hash| hash["name"] }
    end

    def table_name
      [underscore_name, 's'].join
    end

    def underscore_name
      to_s.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
    end
  end

  def attributes
    self.class.attribute_names.reduce({}) do |hash, key|
      hash.merge(key => instance_variable_get("@#{key}"))
    end
  end

  def update(attributes = {})
    attributes.delete(:id)
    assign_attributes(attributes)
    save
  end

  # Saves the attributes to the DB table
  # Called on #create and #update
  def save
    if @id.nil?
      # 1. Create
      DB.execute(build_insert_query)
      @id = DB.last_insert_row_id
    else
      # 2. Update
      DB.execute(build_update_query, *row_values)
    end
  end

  # Destroy
  def destroy
    DB.execute("DELETE FROM #{table_name} WHERE id = ?", @id)
    nil
  end

  def reload
    self.class.find(id)
  end

  # Assigns the values in the attributes hash
  # into instance variable with the respective attributes key
  # on #new, #create, #save, and #update
  def assign_attributes(new_attributes)
    new_attributes.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  private

  def build_insert_query
    "INSERT INTO #{table_name} (#{row_headers.join(',')}) "\
    "VALUES (#{row_values.map { |v| cast(v) }.join(',')})"
  end

  def build_update_query
    "UPDATE #{table_name} SET #{update_statement} WHERE id = #{@id}"
  end

  # Creates an attr_accessor for each table column
  #
  # Given a Posts table with :id, :title and :content,
  # it creates attr_accessor :id, :title, :content
  def initialize_accessors
    self.class.__send__(:attr_accessor, *self.class.__send__(:table_columns))
    # self.class.table_columns.each { |c| self.class.__send__(:attr_accessor, c) }
  end

  def row_headers
    self.class.attribute_names.reject { |attr| attr == "id" }
  end

  def row_values
    row_headers.map { |attr| send(attr) }
  end

  def update_statement
    row_headers.map { |attr| "#{attr} = ?" }.join(',')
  end

  def table_name
    self.class.__send__(:table_name)
  end

  def cast(value)
    case value.class.to_s
    when "String"     then "'#{value}'"
    when "TrueClass"  then "1"
    when "FalseClass" then "2"
    when "NilClass"   then"NULL"
    else
      value.to_s
    end
  end

  # Ensure instances that have the same attributes hash are the same
  def <=>(other)
    attributes <=> other.attributes
  end
end
