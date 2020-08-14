require_relative "../../app/models/programming_language"
require "sqlite3"

db_file_path = File.join(File.dirname(__FILE__), "../support/programming_language_spec.db")
DB = SQLite3::Database.new(db_file_path)
DB.results_as_hash = true

describe ProgrammingLanguage do

  before(:each) do
    DB.execute('DROP TABLE IF EXISTS `programming_languages`;')
    create_statement = "
    CREATE TABLE `programming_languages` (
      `id`  INTEGER PRIMARY KEY AUTOINCREMENT,
      `name` TEXT
    );"
    DB.execute(create_statement)
  end

  describe "self.find (class method)" do
    before do
      DB.execute("INSERT INTO `programming_languages` (name) VALUES ('Ruby')")
    end

    it "should return nil if programming_language not found in database" do
      expect(ProgrammingLanguage.find(42)).to be_nil
    end

    it "should load a programming_language from the database" do
      programming_language = ProgrammingLanguage.find(1)
      expect(programming_language).to_not be_nil
      expect(programming_language).to be_a ProgrammingLanguage
      expect(programming_language.id).to eq 1
      expect(programming_language.name).to eq 'Ruby'
    end

    it "should resist SQL injections" do
      id = '(DROP TABLE IF EXISTS `programming_languages`;)'
      programming_language = ProgrammingLanguage.find(id)  # Inject SQL to delete the programming_languages table...
      expect { ProgrammingLanguage.find(1) }.not_to raise_error
      expect(ProgrammingLanguage.find(1).name).to eq 'Ruby'
    end
  end

  describe "self.all (class method)" do
    it "should load all programming_languages from the database" do
      DB.execute("INSERT INTO `programming_languages` (name) VALUES ('Ruby')")
      DB.execute("INSERT INTO `programming_languages` (name) VALUES ('Python')")
      programming_languages = ProgrammingLanguage.all
      expect(programming_languages.length).to eq 2
      expect(programming_languages).to be_a Array
      expect(programming_languages.first).to be_a ProgrammingLanguage
      expect(programming_languages.first.name).to eq 'Ruby'
      expect(programming_languages.last.name).to eq 'Python'
    end

    it "should return [] when there are no pots in the database" do
      expect(ProgrammingLanguage.all).to eq([])
    end
  end

  describe "self.first (class method)" do
    before do
      DB.execute("INSERT INTO `programming_languages` (name) VALUES ('Ruby')")
      DB.execute("INSERT INTO `programming_languages` (name) VALUES ('Python')")
    end

    it "should load the first programming_language from the database" do
      programming_languages = ProgrammingLanguage.first
      expect(programming_languages).to be_a ProgrammingLanguage
      expect(programming_languages.name).to eq 'Ruby'
    end
  end

  describe "self.second (class method)" do
    before do
      DB.execute("INSERT INTO `programming_languages` (name) VALUES ('Ruby')")
      DB.execute("INSERT INTO `programming_languages` (name) VALUES ('Python')")
    end

    it "should load the second programming_language from the database" do
      programming_language = ProgrammingLanguage.second
      expect(programming_language).to be_a ProgrammingLanguage
      expect(programming_language.name).to eq 'Python'
    end
  end

  describe "self.third (class method)" do
    before do
      DB.execute("INSERT INTO `programming_languages` (name) VALUES ('Ruby')")
      DB.execute("INSERT INTO `programming_languages` (name) VALUES ('Python')")
      DB.execute("INSERT INTO `programming_languages` (name) VALUES ('Elixir')")
    end

    it "should load the third programming_language from the database" do
      programming_language = ProgrammingLanguage.third
      expect(programming_language).to be_a ProgrammingLanguage
      expect(programming_language.name).to eq 'Elixir'
    end
  end

  describe "self.last (class method)" do
    before do
      DB.execute("INSERT INTO `programming_languages` (name) VALUES ('Ruby')")
      DB.execute("INSERT INTO `programming_languages` (name) VALUES ('Python')")
    end

    it "should load the last programming_language from the database" do
      programming_language = ProgrammingLanguage.last
      expect(programming_language).to be_a ProgrammingLanguage
      expect(programming_language.name).to eq 'Python'
    end
  end

  describe "reload" do
    it "should *reload* the programming_language from the database" do
      DB.execute("INSERT INTO `programming_languages` (name) VALUES ('Ruby')")
      programming_language = ProgrammingLanguage.find(1)
      programming_language.name = "Foo"
      expect(programming_language.reload.name).to eq("Ruby")
    end
  end

  describe "save" do
    it "should *insert* the programming_language if it has just been instantiated (ProgrammingLanguage.new)" do
      programming_language = ProgrammingLanguage.new(name: "Ruby")
      programming_language.save
      programming_language = ProgrammingLanguage.find(1)
      expect(programming_language).not_to be_nil
      expect(programming_language.id).to eq 1
      expect(programming_language.name).to eq "Ruby"
    end

    it "should *update* the pprogramming_languageost if it already exists in the DB" do
      DB.execute("INSERT INTO `programming_languages` (name) VALUES ('Ruby')")
      programming_language = ProgrammingLanguage.find(1)
      programming_language.name = "Crystal"
      programming_language.save
      programming_language = ProgrammingLanguage.find(1)
      expect(programming_language.name).to eq("Crystal")
    end

    it "should set the @id when inserting the programming_language the first time" do
      programming_language = ProgrammingLanguage.new(name: "Ruby")
      programming_language.save
      expect(programming_language.id).to eq 1
    end
  end

  describe "update" do
    it "should *update* the programming_language if it already exists in the DB" do
      DB.execute("INSERT INTO `programming_languages` (name) VALUES ('Ruby')")
      programming_language = ProgrammingLanguage.find(1)
      programming_language.update(name: "Crystal")
      expect(programming_language.reload.name).to eq("Crystal")
    end
  end

  describe "destroy" do
    it "should delete the programming_language from the Database" do
      programming_language = ProgrammingLanguage.new(name: "Ruby")
      programming_language.save
      expect(ProgrammingLanguage.find(1)).not_to be_nil
      programming_language.destroy
      expect(ProgrammingLanguage.find(1)).to be_nil
    end
  end

  describe "self.destroy_all (class method)" do
    before do
      DB.execute("INSERT INTO `programming_languages` (name) VALUES ('Ruby')")
      DB.execute("INSERT INTO `programming_languages` (name) VALUES ('Python')")
    end

    it "should delete all programming_languages from the Database" do
      expect(ProgrammingLanguage.find(1)).not_to be_nil
      expect(ProgrammingLanguage.find(2)).not_to be_nil
      ProgrammingLanguage.destroy_all
      expect(ProgrammingLanguage.find(1)).to be_nil
      expect(ProgrammingLanguage.find(2)).to be_nil
    end
  end

  describe "self.count (class method)" do
    it "should count all the programming_languages in the Database" do
      expect(ProgrammingLanguage.count).to eq(0)
      DB.execute("INSERT INTO `programming_languages` (name) VALUES ('Ruby')")
      DB.execute("INSERT INTO `programming_languages` (name) VALUES ('Python')")
      expect(ProgrammingLanguage.count).to eq(2)
    end
  end

  describe "attributes" do
    it "should return an Hash with the programming_language instance attributes" do
      DB.execute("INSERT INTO `programming_languages` (name) VALUES ('Ruby')")
      programming_language = ProgrammingLanguage.find(1)
      expect(programming_language.attributes).to eq({"id" => 1, "name" => "Ruby"})
    end
  end

  describe "self.attribute_names" do
    it "should return an Hash with the ProgrammingLanguage class attribute names" do
      expect(ProgrammingLanguage.attribute_names).to eq(["id", "name"])
    end
  end

  describe "self.where(attribute: value)" do
    before do
      DB.execute("INSERT INTO `programming_languages` (name) VALUES ('Ruby')")
      DB.execute("INSERT INTO `programming_languages` (name) VALUES ('Python')")
    end

    it "should return an array with the programming_languages that match the where condition" do
      programming_language = ProgrammingLanguage.find(1)
      programming_languages = ProgrammingLanguage.where(name: "Ruby")
      expect(programming_languages).to eq([programming_language])
    end

    it "should return [] when there is no match" do
      programming_language = ProgrammingLanguage.where(name: "Unknown")
      expect(programming_language).to eq([])
    end
  end

  describe "assign_attributes" do
    it "should accept a hash of new attributes and assign the values to the instance" do
      programming_language = ProgrammingLanguage.new
      programming_language.assign_attributes(name: 'Ruby')
      expect(programming_language.name).to eq("Ruby")
    end
  end
end
