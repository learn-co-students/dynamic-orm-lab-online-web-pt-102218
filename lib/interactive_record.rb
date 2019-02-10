require_relative "../config/environment.rb"
require 'active_support/inflector'


class InteractiveRecord
  def self.table_name 
    self.to_s.downcase.pluralize
  end
  
  def self.column_names 
    
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end
    column_names.compact
    #remove any nulls 
  end
 
  def initialize(options= {})
    options.each do |k, v|
      self.send("#{k}=", v)
    end
    #setting attributes as the k,v 
  end 
  
  def save
    if self.id
      self.update
    else
      sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
      DB[:conn].execute(sql)
      @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end 
  end 
  # in the above save method, we are creating the table with the attributes
  # below, you need to identify the #_for_insert, so it knows where to pull the information from
  
  def table_name_for_insert
    self.class.table_name 
  end 
  
  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ") 
    
    #returns the column names when called on an instance of the class
    #minus the id- that is created by the database 
    #returns it as a string
  end 
  
  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      #uses the column names array, iterate over it to get the VALUE of the attributes? 
      values << "'#{send(col_name)}'" unless send(col_name).nil?
      #unless the value is nil, assign the column names with values through the att= method 
    end
    values.join(", ")
    
  end 
  
  
  def self.find_by_name(name)
    sql= "SElECT * FROM #{self.table_name} WHERE name = #{name}"
    
    row = DB[:conn].execute(sql, name)
  end 
  
  def self.find_by(hash)
    sql = "SELECT * FROM #{self.table_name} WHERE #{hash.keys[0].to_s} = '#{hash.values[0].to_s}'"
    DB[:conn].execute(sql)
   
  end
  
end


