require_relative "../../app/models/user"
require "sqlite3"

db_file_path = File.join(File.dirname(__FILE__), "../support/users_spec.db")
DB = SQLite3::Database.new(db_file_path)
DB.results_as_hash = true

describe User do

  before(:each) do
    DB.execute('DROP TABLE IF EXISTS `users`;')
    create_statement = "
    CREATE TABLE `users` (
      `id`  INTEGER PRIMARY KEY AUTOINCREMENT,
      `first_name` TEXT,
      `last_name` TEXT
    );"
    DB.execute(create_statement)
  end

  describe "self.find (class method)" do
    before do
      DB.execute("INSERT INTO `users` (first_name, last_name) VALUES ('George', 'Abitbol')")
    end

    it "should return nil if user not found in database" do
      expect(User.find(42)).to be_nil
    end

    it "should load a user from the database" do
      user = User.find(1)
      expect(user).to_not be_nil
      expect(user).to be_a User
      expect(user.id).to eq 1
      expect(user.first_name).to eq 'George'
      expect(user.last_name).to eq 'Abitbol'
    end

    it "should resist SQL injections" do
      id = '(DROP TABLE IF EXISTS `users`;)'
      user = User.find(id)  # Inject SQL to delete the users table...
      expect { User.find(1) }.not_to raise_error
      expect(User.find(1).first_name).to eq 'George'
    end
  end

  describe "self.all (class method)" do
    it "should load all users from the database" do
      DB.execute("INSERT INTO `users` (first_name, last_name) VALUES ('George', 'Abitbol')")
      DB.execute("INSERT INTO `users` (first_name, last_name) VALUES ('Peter', 'Steven')")
      users = User.all
      expect(users.length).to eq 2
      expect(users).to be_a Array
      expect(users.first).to be_a User
      expect(users.first.first_name).to eq 'George'
      expect(users.last.first_name).to eq 'Peter'
    end

    it "should return [] when there are no pots in the database" do
      expect(User.all).to eq([])
    end
  end

  describe "self.first (class method)" do
    before do
      DB.execute("INSERT INTO `users` (first_name, last_name) VALUES ('George', 'Abitbol')")
      DB.execute("INSERT INTO `users` (first_name, last_name) VALUES ('Peter', 'Steven')")
    end

    it "should load the first user from the database" do
      user = User.first
      expect(user).to be_a User
      expect(user.first_name).to eq 'George'
    end
  end

  describe "self.second (class method)" do
    before do
      DB.execute("INSERT INTO `users` (first_name, last_name) VALUES ('George', 'Abitbol')")
      DB.execute("INSERT INTO `users` (first_name, last_name) VALUES ('Peter', 'Steven')")
    end

    it "should load the second user from the database" do
      user = User.second
      expect(user).to be_a User
      expect(user.first_name).to eq 'Peter'
    end
  end

  describe "self.third (class method)" do
    before do
      DB.execute("INSERT INTO `users` (first_name, last_name) VALUES ('George', 'Abitbol')")
      DB.execute("INSERT INTO `users` (first_name, last_name) VALUES ('Peter', 'Steven')")
      DB.execute("INSERT INTO `users` (first_name, last_name) VALUES ('Mike', 'Tyson')")
    end

    it "should load the third user from the database" do
      user = User.third
      expect(user).to be_a User
      expect(user.first_name).to eq 'Mike'
    end
  end

  describe "self.last (class method)" do
    before do
      DB.execute("INSERT INTO `users` (first_name, last_name) VALUES ('George', 'Abitbol')")
      DB.execute("INSERT INTO `users` (first_name, last_name) VALUES ('Peter', 'Steven')")
    end

    it "should load the last user from the database" do
      user = User.last
      expect(user).to be_a User
      expect(user.first_name).to eq 'Peter'
    end
  end

  describe "reload" do
    it "should *reload* the post from the database" do
      DB.execute("INSERT INTO `users` (first_name, last_name) VALUES ('George', 'Abitbol')")
      user = User.find(1)
      user.first_name = "Mike"
      expect(user.reload.first_name).to eq("George")
    end
  end

  describe "save" do
    it "should *insert* the user if it has just been instantiated (User.new)" do
      user = User.new(first_name: "George")
      user.save
      user = User.find(1)
      expect(user).not_to be_nil
      expect(user.id).to eq 1
      expect(user.first_name).to eq "George"
    end

    it "should *update* the user if it already exists in the DB" do
      DB.execute("INSERT INTO `users` (first_name, last_name) VALUES ('George', 'Abitbol')")
      user = User.find(1)
      user.last_name = "Abitbol, Classe man!"
      user.save
      user = User.find(1)
      expect(user.last_name).to eq("Abitbol, Classe man!")
    end

    it "should set the @id when inserting the user the first time" do
      user = User.new(first_name: "George")
      user.save
      expect(user.id).to eq 1
    end
  end

  describe "update" do
    it "should *update* the user" do
      DB.execute("INSERT INTO `users` (first_name, last_name) VALUES ('George', 'Abitbol')")
      user = User.find(1)
      user.update(last_name: "Abitbol, Classe man!")
      expect(user.last_name).to eq("Abitbol, Classe man!")
    end
  end

  describe "destroy" do
    it "should delete the user from the Database" do
      user = User.new(first_name: "George")
      user.save
      expect(User.find(1)).not_to be_nil
      user.destroy
      expect(User.find(1)).to be_nil
    end
  end

  describe "self.destroy_all (class method)" do
    before do
      DB.execute("INSERT INTO `users` (first_name, last_name) VALUES ('George', 'Abitbol')")
      DB.execute("INSERT INTO `users` (first_name, last_name) VALUES ('Peter', 'Steven')")
    end

    it "should delete all users from the Database" do
      expect(User.find(1)).not_to be_nil
      expect(User.find(2)).not_to be_nil
      User.destroy_all
      expect(User.find(1)).to be_nil
      expect(User.find(2)).to be_nil
    end
  end

  describe "self.count (class method)" do
    it "should count all the users in the Database" do
      expect(User.count).to eq(0)
      DB.execute("INSERT INTO `users` (first_name, last_name) VALUES ('George', 'Abitbol')")
      DB.execute("INSERT INTO `users` (first_name, last_name) VALUES ('Peter', 'Steven')")
      expect(User.count).to eq(2)
    end
  end

  describe "attributes" do
    it "should return an Hash with the user instance attributes" do
      DB.execute("INSERT INTO `users` (first_name, last_name) VALUES ('George', 'Abitbol')")
      user = User.find(1)
      expect(user.attributes).to eq({"id" => 1, "first_name" => "George", "last_name" => "Abitbol"})
    end
  end

  describe "self.attribute_names" do
    it "should return an Hash with the User class attribute names" do
      expect(User.attribute_names).to eq(["id", "first_name", "last_name"])
    end
  end

  describe "self.where(attribute: value)" do
    before do
      DB.execute("INSERT INTO `users` (first_name, last_name) VALUES ('George', 'Abitbol')")
      DB.execute("INSERT INTO `users` (first_name, last_name) VALUES ('Peter', 'Steven')")
    end

    it "should return an array with the users that match the where condition" do
      user = User.find(1)
      users = User.where(last_name: "Abitbol")
      expect(users).to eq([user])
    end

    it "should return [] when there is no match" do
      user = User.where(last_name: "Unknown")
      expect(user).to eq([])
    end
  end

  describe "assign_attributes" do
    it "should accept a hash of new attributes and assign the values to the instance" do
      user = User.new
      user.assign_attributes(first_name: "George", last_name: "Abitbol")
      expect(user.first_name).to eq("George")
      expect(user.last_name).to eq("Abitbol")
    end
  end
end