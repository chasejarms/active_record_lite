require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    # ...
    return @columns if @columns
    cols = DBConnection.execute2(<<-SQL).first
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    cols.map!(&:to_sym)
    @columns = cols
  end

  def self.finalize!
    columns.each do |column|
      # create a method for getting the value

      define_method(column) do
        self.attributes[column]
      end

      # create a method for setting the value
      define_method("#{column}=") do |val|
        self.attributes[column] = val
      end

    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    # ...
    @table_name ||= tableize_class
  end

  def self.all
    # ...
    # ...
    all_instance_params = DBConnection.execute(<<-SQL)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
    SQL
    all_instance_params
    parse_all(all_instance_params)
  end

  def self.parse_all(results)
    # ...
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    # ...
    query_result = DBConnection.execute(<<-SQL, id)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
      WHERE
        id = ?
    SQL
    return nil if query_result.empty?
    new(query_result[0])
  end

  def initialize(params = {})
    # ...
    valid_cols = self.class.columns
    params.each do |key, val|
      raise "unknown attribute '#{key}'" unless valid_cols.include?(key.to_sym)
      self.send("#{key}=", val)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    # ...
    @attributes.values
  end

  def insert
    # ...
    columns = @attributes.keys
    col_names = columns.join(", ")
    question_marks = (["?"] * columns.count).join(", ")
    values = attribute_values.join(",")
    query_result = DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    # ...
    # the minus takes out the primary key because we don't want to give
    # the user the option to change their primary key.
    set_line = (self.class.columns
      .map { |attrs| "#{attrs} = ?" } - ["id"]).join(", ")
    query_result = DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        id = ?
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def save
    # ...
    id = attributes[:id]
    if id
      update
    else
      insert
    end
  end

  private

  def self.tableize_class
    self.to_s.tableize
  end
end
