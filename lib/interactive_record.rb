require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "PRAGMA table_info('#{table_name}')"

    table_name = DB[:conn].execute(sql)
    column_names = []

    table_name.each do |col|
      column_names << col["name"]
    end
    column_names.compact
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|column_name| column_name == "id"}.join(", ")
  end

  values = []

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  def save
    sql = <<-SQL
    INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})
    SQL
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end


  def table_name_for_insert
    self.class.table_name
  end

  def self.find_by_name(name)
    sql = <<-SQL
    SELECT * FROM #{self.table_name} WHERE name = '#{name}'
    SQL
    DB[:conn].execute(sql)
  end

  def self.find_by(attribute)
    sql = "SELECT * FROM #{self.table_name} WHERE #{attribute.to_a.flatten[0]} = #{attribute.to_a.flatten[0]} LIMIT 1"
    DB[:conn].execute(sql)
  end

end
