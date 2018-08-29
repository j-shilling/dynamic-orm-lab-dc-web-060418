require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "PRAGMA table_info('#{self.table_name}')"
    DB[:conn].execute(sql).map do |col|
      col["name"]
    end.compact
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

  def self.find_by(attrs)
    attrs.each do |key, value|
      sql = "SELECT * FROM #{table_name} WHERE #{key} = '#{value}'"
      return DB[:conn].execute(sql)
    end
  end

  def initialize(opts = {})
    opts.each do |key, val|
      self.send("#{key}=", val)
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|e| e == "id"}.join (', ')
  end

  def values_for_insert
    vals = []

    self.class.column_names.each do |col_name|
      vals << "'#{send(col_name)}'" unless send(col_name).nil?
    end

    vals.join(', ')
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)

    id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    send("id=", id)
  end


end
