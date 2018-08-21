require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "PRAGMA table_info('#{self.table_name}')"

    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each{|row| column_names << row["name"]}
    column_names.compact
  end

  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
  end

  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  def save
    sql = "INSERT INTO #{table_name} (#{col_names_for_insert}) VALUES (#{value_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert
    self.class.table_name
  end

  def values_for_insert
    values=[]
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nill?
    end
    values.join(",")
  end

  def col_names_for_insert
    self.class.colimn_names.delete_if {|col| col == "id"}.join(",")
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name '#{name}'"
    DB[:conn].execute(sql)
  end

  def self.find_by(options = {})
  sql = <<-SQL
    SELECT * FROM #{self.table_name}
    WHERE #{options.keys.first.to_s} = "#{options[options.keys.first]}"
  SQL
  DB[:conn].execute(sql)
end
end
