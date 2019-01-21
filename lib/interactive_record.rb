require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  
  def self.table_name
    self.to_s.downcase.pluralize
  end
  
  def self.column_names
    DB[:conn].results_as_hash = true
    sql = "PRAGMA table_info('#{table_name}')"
    table_data = DB[:conn].execute(sql)
    # binding.pry
    table_data.map { |col| col["name"] }
  end
  
  def initialize(options={})
    options.each do |k, v|
      self.send("#{k}=", v)
    end
    self
  end
  
  def table_name_for_insert
    self.class.table_name
  end
  
  def col_names_for_insert
    col_names = self.class.column_names.delete_if { |name| name == "id" }.join(', ')
  end
  
  def values_for_insert
    col_names_for_insert.split(', ').map do |col|
      "'#{self.send("#{col}")}'" || "NULL"
    end.join(', ')
  end
  
  def placeholders_for_insert
    Array.new(self.class.column_names.count - 1, '?').join(', ')
  end
  
  def save
    sql = "INSERT INTO #{table_name_for_insert} \
            (#{col_names_for_insert}) \
            VALUES (#{values_for_insert});"
    DB[:conn].execute(sql)
    # binding.pry
    sql = "SELECT last_insert_rowid() FROM #{table_name_for_insert}"
    self.id = DB[:conn].execute(sql)[0][0]
  end
  
  def self.find_by_name(name)
    sql = "SELECT * FROM #{table_name} WHERE name = ?"
    DB[:conn].execute(sql, name)
  end
  
  def self.find_by(att_hash)
    sql = "SELECT * FROM #{table_name} WHERE #{att_hash.keys.first} = ?"
    DB[:conn].execute(sql, att_hash.values.first)
  end
  
  
  
end