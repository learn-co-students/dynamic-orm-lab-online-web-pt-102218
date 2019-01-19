require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  def self.table_name
    "#{self.to_s.downcase}s"
  end

  def self.column_names
    DB[:conn].results_as_hash = true
    sql = "pragma table_info('#{table_name}')"
    schema_hash = DB[:conn].execute(sql)
    schema_hash.map do |hash|
        hash['name']
    end
  end

  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.tap { |column| column.delete("id") }.join(", ")
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |column|
      values << "'#{send(column)}'" unless send(column).nil?
    end
    values.join(", ")
  end

  def save
    sql = <<-SQL
      INSERT INTO #{self.class.table_name} (#{self.col_names_for_insert})
      VALUES (#{self.values_for_insert});
    SQL
    DB[:conn].execute(sql)
    self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.class.table_name}")[0][0]
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT * FROM #{self.table_name}
      WHERE name = ?;
    SQL
    DB[:conn].execute(sql, name)
  end

  def self.find_by(search_hash)
    values = []
    search_hash.each do |key, value|
      values << key
      values << value
    end
    sql = "SELECT * FROM #{self.table_name} WHERE #{values[0]} = '#{values[1]}'"
    DB[:conn].execute(sql)
  end
end