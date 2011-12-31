# NakedModel
You create awesome models, why bother with writing yet another passthrough controller or twelve?

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
Helpful hint: when dealing with JSON on the console it's useful to do:
```shell
alias pp_json="ruby -r json -e 'jj JSON.parse gets'"
```

config.ru:

```ruby
require 'active_record'

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => File.dirname(__FILE__) + "/nm.sqlite3"
)

ActiveRecord::Schema.define do
  create_table "topics" do |t|
    t.text     "name"
  end
  create_table "comments" do |t|
    t.text     "comment"
    t.integer  "topic_id"
    t.timestamps
  end
end

class Topic < ActiveRecord::Base
  has_many :comments
end
class Comment < ActiveRecord::Base
  belongs_to :topic
end

require 'naked_model'
require 'naked_model/adapter/active_record'
run NakedModel.new( :adapters => [NakedModel::Adapter::ActiveRecord::Collection.new, NakedModel::Adapter::ActiveRecord::Object.new] )
```

```shell
$ rackup
```

And we're off.

You now have a webserver up and running, serving your models and
responding to GETs, POSTs, and PUTs.

Let's load it up. We'll first post to the collection with a body
representing the new resource.

```shell
$ curl -s -d '{ "name": "kitties" }' localhost:9292/topics | pp_json
{
  "id": 1,
  "name": "kitties",
  "links": [
    {
      "rel": "self",
      "href": "http://localhost:9292/topics/1"
    },
    {
      "rel": "comments",
      "href": "http://localhost:9292/topics/1/comments"
    }
  ]
}
```

Fun things to note! The "links" properties include the array of
relationships that our new topic has. We can use this to post new
comments to it:

```shell
$ curl -s -d '{ "comment": "I love kitties." }' localhost:9292/topics/1/comments | pp_json
{
  "comment": "I love kitties.",
  "created_at": "2011-12-31T11:58:19-08:00",
  "id": 1,
  "topic_id": 1,
  "updated_at": "2011-12-31T11:58:19-08:00",
  "links": [
    {
      "rel": "self",
      "href": "http://localhost:9292/topics/1/comments/1"
    },
    {
      "rel": "topic",
      "href": "http://localhost:9292/topics/1/comments/1/topic"
    }
  ]
}
```

And let's see the results. Our topic:

```shell
$ curl -s localhost:9292/topics/1 | pp_json
{
  "id": 1,
  "name": "kitties",
  "links": [
    {
      "rel": "self",
      "href": "http://localhost:9292/topics/1"
    },
    {
      "rel": "comments",
      "href": "http://localhost:9292/topics/1/comments"
    }
  ]
}
```

And the comments for it:

```shell
$ curl -s localhost:9292/topics/1/comments | pp_json
[
  {
    "comment": "I love kitties.",
    "created_at": "2011-12-31T11:58:19-08:00",
    "id": 1,
    "topic_id": 1,
    "updated_at": "2011-12-31T11:58:19-08:00",
    "links": [
      {
        "rel": "self",
        "href": "http://localhost:9292/topics/1/comments/1"
      },
      {
        "rel": "topic",
        "href": "http://localhost:9292/topics/1/comments/1/topic"
      }
    ]
  }
]
```
