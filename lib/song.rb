require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class Song


  def self.table_name #method that grabs us the table name
    self.to_s.downcase.pluralize #pluralize is available via the active_support/inflector code library that we require above.
  end

  def self.column_names #method that grabs the column values
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')" #this is to query a table for the names of all its columns -> returns an array of hashes because of #results_as_hash()

    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |column|
      column_names << column["name"]
    end
    column_names.compact #compact is used to get rid of any nil values that may end up in our collection
  end

  self.column_names.each do |col_name| #we can tell our class to have attr_accessors named after each column name
    attr_accessor col_name.to_sym #attr_accessor must be symbols
  end

  def initialize(options={}) #metaprogramming initialize method to take a hash of key value arugments without explicitly naming them
    options.each do |property, value|
      self.send("#{property}=", value) #send() interpolates the name of each key as a method that we set equal to the value (as long as each as a corresponding attr_accessor the method will work)
    end
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert #in order to use a class method inside an instance method - this is to access the table name we want to insert into
    self.class.table_name
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ") #sqlite already creates an ID column when we insert so we want to check/remove ID from the insert
  end # the join takes the array of column names and makes them a comma separated list to use in our sql query.

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end
