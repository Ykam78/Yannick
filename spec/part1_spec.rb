# spec/app_spec.rb
require File.expand_path '../spec_helper.rb', __FILE__

describe Post do
    it { should have_property           :id }
    it { should have_property           :caption  }
    it { should have_property           :image_url  }
    it { should have_property           :created_at  }
    it { should have_property           :user_id }
end

describe Like do
    it { should have_property           :id }
    it { should have_property           :user_id  }
    it { should have_property           :post_id  }
    it { should have_property           :created_at  }
end

describe Comment do
    it { should have_property           :id }
    it { should have_property           :user_id  }
    it { should have_property           :post_id  }
    it { should have_property           :text  }
    it { should have_property           :created_at }
end