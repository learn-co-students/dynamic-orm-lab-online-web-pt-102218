require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'
class InteractiveRecord
    def self.table_name
        "#{self.to_s.downcase}s"
    end

    def self.column_names
        DB[:conn].results_as_hash = true

        sql = "pragma table_info('#{table_name}');"
        table_info = DB[:conn].execute(sql)
        out = []
        table_info.each do |i|
            out.push(i["name"])
        end
        out.compact
    end

    def initialize(x={})
        x.each do |k, v|
          self.send("#{k}=", v)
        end
    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names[1..self.class.column_names.length-1].join(", ")
    end

    def values_for_insert
        self.class.column_names.map{|col|
            #binding.pry
            if send(col) != nil then 
                "'"+send(col).to_s+"'"
            else
                ""
            end
        }[1..self.class.column_names.length].join(", ")
    end

    def save
        DB[:conn].execute("INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert});")
        @id=DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
        sql = "SELECT * FROM #{self.table_name} WHERE name = ?"
        DB[:conn].execute(sql, name)
    end

    def self.find_by(attributes)
        DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE #{attributes.keys[0][0..-1]} = '#{attributes.values[0]}'")
    end

end