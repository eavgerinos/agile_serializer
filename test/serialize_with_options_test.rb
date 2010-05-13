require 'test_helper'

class User < ActiveRecord::Base
  has_many :posts
  has_many :blog_posts
  has_many :check_ins
  
  serialize_with_options do
    methods   :post_count
    includes  :posts
    except    :email
  end

  serialize_with_options(:deep) do
    includes :check_ins
  end

  serialize_with_options(:with_email) do
    methods   :post_count
    includes  :posts
  end

  serialize_with_options(:with_comments) do
    includes  :posts => { :include => :comments }
  end
  
  serialize_with_options(:with_check_ins) do
    includes :check_ins
    dasherize false
    skip_types true
  end

  def post_count
    self.posts.count
  end
end

class Post < ActiveRecord::Base
  has_many :comments
  belongs_to :user

  serialize_with_options do
    only :title
    includes :user, :comments
  end

  serialize_with_options(:deep) do
    includes :user
  end

  serialize_with_options(:with_email) do
    includes :user, :comments
  end
end

class BlogPost < Post
  serialize_with_options(:with_email) do
    includes :user
  end
end

class Comment < ActiveRecord::Base
  belongs_to :post
end

class CheckIn < ActiveRecord::Base
  belongs_to :user

  serialize_with_options(:deep) do
    only :code_name
  end

  serialize_with_options do
    only :code_name
    includes :user
  end
end

class SerializeWithOptionsTest < Test::Unit::TestCase
  def self.should_serialize_with_options
    should "include active_record attributes" do
      assert_equal @user.name, @user_hash["name"]
    end

    should "include specified methods" do
      assert_equal @user.post_count, @user_hash["post_count"]
    end

    should "exclude specified attributes" do
      assert_equal nil, @user_hash["email"]
    end

    should "exclude attributes not in :only list" do
      assert_equal nil, @post_hash["content"]
    end

    should "include specified associations" do
      assert_equal @post.title, @user_hash["posts"].first["title"]
    end
    
    should "be identical in inherited model" do
      assert_equal @post_hash["title"], @blog_post_hash["title"]
    end
    
    should "include specified methods on associations" do
      assert_equal @user.post_count, @post_hash["user"]["post_count"]
    end

    should "exclude specified methods on associations" do
      assert_equal nil,  @post_hash["user"]["email"]
    end

    should "not include associations of associations" do
      assert_equal nil, @user_hash["posts"].first["comments"]
    end

    should "include association without serialization options properly" do
      assert_equal @comment.content, @post_hash["comments"].first["content"]
    end
    
    should "override sets on inherited models" do
      assert_equal nil, @blog_post_hash["comments"].first
    end
  end

  context "propagate includes" do
    setup do
      @user = User.create(:name => "John User", :email => "john@example.com")
      @post = @user.posts.create(:title => "Hello World!", :content => "Welcome to my blog.")
      @checkin = @user.check_ins.create(:code_name => "Natasa")
    end

    should "Include deep relations" do
      post_hash = JSON.parse @post.to_json(:flavor => :deep)
      assert_equal @user.email, post_hash["user"]["email"]
      assert_equal @checkin.code_name, post_hash["user"]["check_ins"].first['code_name']
    end
      
  end

end
