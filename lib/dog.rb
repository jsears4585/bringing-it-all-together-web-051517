require 'pry'

class Dog
  attr_accessor :name, :breed, :id

  def initialize attr_hash
    @name = attr_hash[:name]
    @breed = attr_hash[:breed]
    @id = nil
  end

  def self.create_table
    sql = <<-sql
      CREATE TABLE IF NOT EXISTS dogs (
        id INTEGER PRIMARY KEY,
        name TEXT,
        breed TEXT
      )
    sql
    DB[:conn].execute(sql)
  end

  def self.drop_table
    DB[:conn].execute("DROP TABLE dogs")
  end

  def save
    if self.id
      self.update
    else
      sql = <<-sql
        INSERT INTO dogs (name, breed)
        VALUES (?, ?)
      sql
      DB[:conn].execute(sql, self.name, self.breed)
      @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
      self
    end
  end

  def self.create hash
    dog = Dog.new(name: hash[:name], breed: hash[:breed])
    dog.save
    dog
  end

  def self.find_by_id id
    sql = <<-sql
      SELECT *
      FROM dogs
      WHERE id = ?
    sql
    row = DB[:conn].execute(sql, id)[0]
    dog = Dog.new(name: row[1], breed: row[2])
    dog.id = id
    dog
  end

  def self.find_by_name name
    sql = <<-sql
      SELECT * FROM dogs
      WHERE name = ?
    sql
    row = DB[:conn].execute(sql, name)[0]
    dog = self.create(name: row[1], breed: row[2])
    dog.id = row[0]
    dog
  end

  def self.find_or_create_by(name:, breed:)
    dog = DB[:conn].execute("SELECT * FROM dogs WHERE name = ? AND breed = ?", name, breed)
    if !dog.empty?
      dog_data = dog[0]
      dog = Dog.new(name: dog_data[1], breed: dog_data[2])
      dog.id = dog_data[0]
      dog
    else
      dog = self.create(name: name, breed: breed)
    end
    dog
  end

  def self.new_from_db row
    dog = Dog.new(name: row[1], breed: row[2])
    dog.save
    dog
  end

  def update
    sql = <<-sql
      UPDATE dogs SET name = ?, breed = ?
      WHERE id = ?
    sql
    DB[:conn].execute(sql, self.name, self.breed, self.id)
    self
  end
end
