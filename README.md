# NakedModel
You create awesome models, why bother with passthrough controllers?

NakedModel wraps up regular Ruby objects in a REST-ish interface, ready
for Rack mounting. Specialized adapters for ActiveRecord, MongoMapper,
and more are included.

## Quick Start
Install the gem.

```shell
$ gem install naked_model
```

In your config.ru:

```ruby
require 'your_models.rb'
require 'naked_model'

run NakedModel.new( :adapters => :active_record )
```

And run it.

```shell
$ rackup
...
$ curl localhost:9292/model_class/1
{
  "your_model": "goes here"
}
```



## Example

config.ru:

```ruby
require 'active_record'

# Set up some basic ActiveRecord models
ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => ':memory:'
)

ActiveRecord::Schema.define do
  create_table "topic" do |t|
    t.text     "name"
  end
  create_table "comment" do |t|
    t.integer  "artist_id"
    t.text     "comment"
    t.timestamps
  end 
end

class Topic < ActiveRecord::Base
  has_many :comments
end
class Cd < ActiveRecord::Base
  belongs_to :topic
end

# And run NakedModel
require 'naked_model'
run NakedModel.new( :adapters => :active_record )
```

```shell
$ rackup
```

And we're off.

You now have a webserver up and running, serving your models and
responding to GETs, POSTs, and PUTs.






