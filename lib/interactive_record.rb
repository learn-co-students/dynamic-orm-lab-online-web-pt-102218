require_relative "../config/environment.rb"
# require 'active_support/inflector'

class InteractiveRecord
    def self.table_name
        self.to_s.downcase + "s"
    end

    def self.column_names
        DB[:conn].results_as_hash = true

        sql = "pragma table_info('#{table_name}');"
        table_info = DB[:conn].execute(sql)
        out = []
        table_info.each do |i|
            out << i["name"]
        end
        out.compact
    end 

    def initialize(attributes={})
        attributes.each do |key, val|
            self.send("#{key}=", val)
        end
    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names.reject {|i| i == "id"}.join(', ')
    end

    def values_for_insert
        out = []
        self.class.column_names.each do |i|
            out << "'#{send(i)}'" unless send(i).nil?
        end
        out.join(', ')
    end

    def save
        sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert});"
        out = DB[:conn].execute(sql)
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
        sql = "SELECT * FROM #{self.table_name} WHERE name = ?"
        DB[:conn].execute(sql, name)
    end

    def self.find_by(attributes)
        DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE #{attributes.keys[0][0..-1]} = '#{attributes.values[0]}'")
    end
        
end