# Adds shared behaviour to model classes
#
# == Creation
#
# Record accepts constructor parameters in a hash.
#
#   post = Post.new(title: "Article 1")
#   post.title # => "Article 1"
class Record
  include Comparable

  def initialize(attributes = {})
    initialize_accessors
    assign_attributes(attributes)
  end

  # Class Methods:
  class << self
    # Returns an array with the table column names
    #
    #   class Post < Record
    #   end
    #   Post.attribute_names # => ["id", "title", "url", "votes"]
    def attribute_names
      table_columns
    end

    # Creates a record in the DB an returns an instance
    def create(attributes = {})
      new(attributes).save
    end

    # Find a record in the DB by id
    #
    #   Post.find(3)
    def find(id)
      result = DB.execute("SELECT * FROM #{table_name} WHERE id = ?", id).first
      result.nil? ? nil : build_record(result)
    end

    # Returns an array of instances for all records in the DB
    def all
      DB.execute("SELECT * FROM #{table_name}")
        .map { |row| build_record(row) }
    end

    # Returns the instance of the last record in the DB
    def last
      all.last
    end

    # Returns the instance of the first record in the DB
    def first
      all.first
    end

    # Returns the instance of the second record in the DB
    def second
      all[1]
    end

    # Returns the instance of the third record in the DB
    def third
      all[2]
    end

    # Counts the number of records in the DB
    def count
      DB.execute("SELECT COUNT(id) FROM #{table_name}")
        .first["COUNT(id)"]
    end

    # Destroys all the records for the model in the DB
    def destroy_all
      DB.execute("DELETE FROM #{table_name}")
      nil
    end

    # Builds a simple where clause condition
    # an returns an array of instances with matches
    #
    #   Post.where(title: "Amazing")
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
    self.class.send(:attr_accessor, *self.class.send(:table_columns))
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
    self.class.send(:table_name)
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
