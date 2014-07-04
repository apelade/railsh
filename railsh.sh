#! /bin/bash
## Rails 3 script for project with models and many-to-many
## Note: suppressing output of git commit
 
### Might work on rails4, untried
rails -v

GEMFILE_BAK=./Gemfile
PROJ=${PROJ:-blab}
if [ ! $1 ] ; then
  read -p "Enter name for rails project. Default is \"$PROJ\" " PROVIDE
  if [ -n $PROVIDE ] ; then
    PROJ = $PROVIDE
  fi
fi
if [ -d "$PROJ" ] ; then
  read -p 'Directory exists and will be overwritten. Ctrl+C to exit. '
  rm -rfI $PROJ
fi
 
 
echo "
*** Make project directories and init project :
"
mkdir $PROJ
cp $GEMFILE_BAK $PROJ/Gemfile
cd $PROJ
bundle install
rails new . --skip-gemfile
git init .
git add .
git commit -am "initial commit of new project" --quiet
git checkout -b add-models
 
 
echo "
*** Add database tables by running the rails generator, and migrate :
"
rails g scaffold Tag name:string
rails g scaffold Product name:string model:string price:decimal text:text
rails g scaffold ProductTag product:references tag:references #model?
bundle exec rake db:migrate
bundle exec rake db:test:prepare
 
 
echo "
*** Manually modify the model files to add has_many associations :
"
echo "
class Product < ActiveRecord::Base
  attr_accessible :model, :name, :price, :text
  has_many :product_tags
  has_many :tags, :through => :product_tags
end
" > app/models/product.rb
echo "
class Tag < ActiveRecord::Base
  attr_accessible :name
  has_many :product_tags
  has_many :products, :through => :product_tags
end
" > app/models/tag.rb
cat app/models/product.rb app/models/tag.rb
echo "
Now you should be able to use the relationships in rails console:
prod = Product.create({name: 'ted'})
prod.tags.create({name: 'taggy'})  
"
git add .
git commit -am "added product-m2m-tag associations through product_tag" --quiet
git checkout master
git merge add-models --quiet
 
 
echo "
*** Add a compound index on two columns in a standalone migration :
"
git checkout -b add-index-prod-tag
echo "rails g migration AddIndexToProductTag"
echo "Manually edit the resulting file in db/migrate/ to handle the index."
rails g migration AddIndexToProductTag
echo "
class AddIndexToProductTag < ActiveRecord::Migration
  def up
    add_index :product_tags, [:product_id, :tag_id], unique: true
  end
  def down
    remove_index :product_tags, [:product_id, :tag_id]
  end
end
" > db/migrate/*_add_index_to_product_tag.rb
cat db/migrate/*_add_index_to_product_tag.rb
bundle exec rake db:migrate
bundle exec rake db:test:prepare
 
git add .
git commit -am "added compound unique index on table product_tags" --quiet
git checkout master
git merge add-index-prod-tag
 
 
############################################################
 
 
echo "
*** Manually enter model tests, and run with simplecov gem for coverage metric :
"
#git checkout master
git checkout -b add-model-spec
echo "gem 'rspec-rails'" >> Gemfile
echo "gem 'simplecov'" >> Gemfile
bundle install --quiet
rails g rspec:install
 
pwd
ls spec
mkdir -p spec/models
#touch spec/models/tag_spec.rb

echo "
require 'spec_helper'
 
describe Tag do
  it '#create raises no errors' do
    expect { tag = Tag.create({name: 'omg'}) }.not_to raise_error
  end
  it '#create save in database' do
    tag = Tag.create({name: 'peachy'})
    expect(tag).to be_persisted
  end
end
" > spec/models/tag_spec.rb
 
 
echo "
require 'spec_helper'
 
describe Product do
  it '#create raises no errors' do
    expect { product = Product.create({name: 'firewood'}) }.not_to raise_error
  end
  it '#create save in database' do
    prod = Product.create({name: 'Peach'})
    expect(prod).to be_persisted
  end
end
" > spec/models/product_spec.rb
 
 
echo "
require 'spec_helper'
 
describe ProductTag do
  it 'Product #tags.create' do
    prod = Product.create({name: 'Umbrella'})
    expect { prod.tags.create({name: 'taggy'}) }.to change{prod.tags.count}.from(0).to(1)
  end
  it 'Tag #products.create' do
    tag = Tag.create({name: 'Tagster'})
    expect { tag.products.create({name: 'Sale!'}) }.to change{tag.products.count}.from(0).to(1)
  end  
end
" > spec/models/product_tag_spec.rb
 
cat spec/models/*_spec.rb
 
# Insert require over first line in spec helper, a bad comment
COVERAGE="require 'simplecov'\nSimpleCov.start"
sed -i -e "1s/^.*$/$COVERAGE/" spec/spec_helper.rb
#bundle exec rake spec runs all the controller specs too which fail
bundle exec rspec spec/models
 
echo "coverage" >> .gitignore
git add .
git commit -am "Added model spec and simplecov" --quiet
git checkout master
git merge add-model-spec
 
firefox ./coverage/index.html &> /dev/null &
