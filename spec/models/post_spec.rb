require_relative "../../app/models/post"
require "sqlite3"

db_file_path = File.join(File.dirname(__FILE__), "../support/posts_spec.db")
DB = SQLite3::Database.new(db_file_path)
DB.results_as_hash = true

describe Post do

  before(:each) do
    DB.execute('DROP TABLE IF EXISTS `posts`;')
    create_statement = "
    CREATE TABLE `posts` (
      `id`  INTEGER PRIMARY KEY AUTOINCREMENT,
      `title` TEXT,
      `url` TEXT,
      `votes`  INTEGER
    );"
    DB.execute(create_statement)
  end

  describe "self.find (class method)" do
    before do
      DB.execute("INSERT INTO `posts` (title) VALUES ('Hello world')")
    end

    it "should return nil if post not found in database" do
      expect(Post.find(42)).to be_nil
    end

    it "should load a post from the database" do
      post = Post.find(1)
      expect(post).to_not be_nil
      expect(post).to be_a Post
      expect(post.id).to eq 1
      expect(post.title).to eq 'Hello world'
    end

    it "should resist SQL injections" do
      id = '(DROP TABLE IF EXISTS `posts`;)'
      post = Post.find(id)  # Inject SQL to delete the posts table...
      expect { Post.find(1) }.not_to raise_error
      expect(Post.find(1).title).to eq 'Hello world'
    end
  end

  describe "self.all (class method)" do
    it "should load all posts from the database" do
      DB.execute("INSERT INTO `posts` (title) VALUES ('Article 1')")
      DB.execute("INSERT INTO `posts` (title) VALUES ('Article 2')")
      posts = Post.all
      expect(posts.length).to eq 2
      expect(posts).to be_a Array
      expect(posts.first).to be_a Post
      expect(posts.first.title).to eq 'Article 1'
      expect(posts.last.title).to eq 'Article 2'
    end

    it "should return [] when there are no pots in the database" do
      expect(Post.all).to eq([])
    end
  end

  describe "self.first (class method)" do
    before do
      DB.execute("INSERT INTO `posts` (title) VALUES ('Article 1')")
      DB.execute("INSERT INTO `posts` (title) VALUES ('Article 2')")
    end

    it "should load the first post from the database" do
      post = Post.first
      expect(post).to be_a Post
      expect(post.title).to eq 'Article 1'
    end
  end

  describe "self.second (class method)" do
    before do
      DB.execute("INSERT INTO `posts` (title) VALUES ('Article 1')")
      DB.execute("INSERT INTO `posts` (title) VALUES ('Article 2')")
    end

    it "should load the second post from the database" do
      post = Post.second
      expect(post).to be_a Post
      expect(post.title).to eq 'Article 2'
    end
  end

  describe "self.third (class method)" do
    before do
      DB.execute("INSERT INTO `posts` (title) VALUES ('Article 1')")
      DB.execute("INSERT INTO `posts` (title) VALUES ('Article 2')")
      DB.execute("INSERT INTO `posts` (title) VALUES ('Article 3')")
    end

    it "should load the third post from the database" do
      post = Post.third
      expect(post).to be_a Post
      expect(post.title).to eq 'Article 3'
    end
  end

  describe "self.last (class method)" do
    before do
      DB.execute("INSERT INTO `posts` (title) VALUES ('Article 1')")
      DB.execute("INSERT INTO `posts` (title) VALUES ('Article 2')")
    end

    it "should load the last post from the database" do
      post = Post.last
      expect(post).to be_a Post
      expect(post.title).to eq 'Article 2'
    end
  end

  describe "reload" do
    it "should *reload* the post from the database" do
      DB.execute("INSERT INTO `posts` (title) VALUES ('Article 1')")
      post = Post.find(1)
      post.title = "Wrong title!"
      expect(post.reload.title).to eq("Article 1")
    end
  end

  describe "save" do
    it "should *insert* the post if it has just been instantiated (Post.new)" do
      post = Post.new(title: "Article 1")
      post.save
      post = Post.find(1)
      expect(post).not_to be_nil
      expect(post.id).to eq 1
      expect(post.title).to eq "Article 1"
    end

    it "should *update* the post if it already exists in the DB" do
      DB.execute("INSERT INTO `posts` (title) VALUES ('Article 1')")
      post = Post.find(1)
      post.title = "Article 1 updated"
      post.save
      post = Post.find(1)
      expect(post.title).to eq("Article 1 updated")
    end

    it "should set the @id when inserting the post the first time" do
      post = Post.new(title: "Article 1")
      post.save
      expect(post.id).to eq 1
    end
  end

  describe "update" do
    it "should *update* the post if it already exists in the DB" do
      DB.execute("INSERT INTO `posts` (title) VALUES ('Article 1')")
      post = Post.find(1)
      post.title = "Article 1 updated"
      post.save
      post = Post.find(1)
      expect(post.title).to eq("Article 1 updated")

      DB.execute("INSERT INTO `posts` (title) VALUES ('Article 1')")
      post = Post.find(1)
      post.update(title: "Fantastic Article!")
      expect(post.reload.title).to eq("Fantastic Article!")
    end
  end

  describe "destroy" do
    it "should delete the post from the Database" do
      post = Post.new(title: "Article 1")
      post.save
      expect(Post.find(1)).not_to be_nil
      post.destroy
      expect(Post.find(1)).to be_nil
    end
  end

  describe "self.destroy_all (class method)" do
    before do
      DB.execute("INSERT INTO `posts` (title) VALUES ('Article 1')")
      DB.execute("INSERT INTO `posts` (title) VALUES ('Article 2')")
    end

    it "should delete all posts from the Database" do
      expect(Post.find(1)).not_to be_nil
      expect(Post.find(2)).not_to be_nil
      Post.destroy_all
      expect(Post.find(1)).to be_nil
      expect(Post.find(2)).to be_nil
    end
  end

  describe "self.count (class method)" do
    it "should count all the posts in the Database" do
      expect(Post.count).to eq(0)
      DB.execute("INSERT INTO `posts` (title) VALUES ('Article 1')")
      DB.execute("INSERT INTO `posts` (title) VALUES ('Article 2')")
      expect(Post.count).to eq(2)
    end
  end

  describe "attributes" do
    it "should return an Hash with the post instance attributes" do
      DB.execute("INSERT INTO `posts` (title) VALUES ('Article 1')")
      post = Post.find(1)
      expect(post.attributes).to eq({"id" => 1, "title" => "Article 1", "url" => nil, "votes" => nil})
    end
  end

  describe "self.attribute_names" do
    it "should return an Hash with the Post class attribute names" do
      expect(Post.attribute_names).to eq(["id", "title", "url", "votes"])
    end
  end

  describe "self.where(attribute: value)" do
    before do
      DB.execute("INSERT INTO `posts` (votes) VALUES (10)")
      DB.execute("INSERT INTO `posts` (votes) VALUES (900)")
    end

    it "should return an array with the posts that match the where condition" do
      post = Post.find(2)
      posts = Post.where(votes: 900)
      expect(posts).to eq([post])
    end

    it "should return [] when there is no match" do
      post = Post.where(votes: "Unknown")
      expect(post).to eq([])
    end
  end

  describe "assign_attributes" do
    it "should accept a hash of new attributes and assign the values to the instance" do
      post = Post.new
      post.assign_attributes(title: 'Article 1', url: 'www.example.com', votes: 30)
      expect(post.title).to eq("Article 1")
      expect(post.url).to eq("www.example.com")
      expect(post.votes).to eq(30)
    end
  end
end
