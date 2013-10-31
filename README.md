#Elasticbone

NOTE: This project is still in development, and not production ready. Though hopefully soon it will be.

[Elasticsearch](http://www.elasticsearch.org/) is an awesome document store, with a nice rest api.
[Backbone](http://backbonejs.org/) is an awesome MVC framework, where the model are defined to interact with a rest api.
Elasticbone is an extension making it easy for Backbone models to be connected to Elasticsearch documents.

Elasticbone is (should be) usable in both a browser, or node.js server.

To install

```
npm install elasticbone
```

##Examples
The easiest way to describe elasticbone is to give a few examples based on creating a blog.

```
Elasticbone = require 'elasticbone'

class User extends Elasticbone.ElasticModel

class Post extends Elasticbone.ElasticModel

class Posts extends Elasticbone.ElasticCollection
  model: Post
```

Elasticmodels and elasticcollections reference an elasticsearch server, index and type.

The default type is the snakecase of the (presumably camelcase) name of the model, in the case of a collection it is the snakecase of its defined model. It can be overwritten by setting a ```type```.

```
class User extends Elasticbone.ElasticModel
  server: 'localhost:9000' 
  index: 'blog'

class Post extends Elasticbone.ElasticModel
  server: 'localhost:9000' 
  index: 'blog'

class Posts extends Elasticbone.ElasticCollection
  server: 'localhost:9000' 
  index: 'blog'
```

###Relationships
Elasticbone also lets you define relationships between backbone models and elasticsearch documents.

To relate models together the ```has``` function is used, and options are passed to it.
The basic structure is ```has 'attribute', Model, {options}```

By default the relationship will be treated as a subdocument, e.g.

Given a ```Post``` document in elasticsearch looks like:

```
{
tags: [{name: 'foo'}, {name: 'bar'}]
}
```

This relationships would be defined using elasticbone as such,

```
class Tag extends Backbone.Model

class Tags extends Backbone.Collection

class Post extends Elasticbone.ElasticModel
  ...
  @has 'tags', Tags
```

NOTE: Tag is not an ElasticModel as it is not a document in Elasticsearch.

###has seperate ElasticModel relationship

```
class Posts extends Elasticbone.ElasticCollection
  fetch_query: -> {"query":{"field": {"author":"\"#{this.get('user').name}\""}}}
    
class User extends Elasticbone.ElasticModel
  ...
  @has 'posts', Posts, method: 'fetch'

user = new User(id: 1)
$.when(user.fetch()).done( (user) -> user.get('posts'))
```

Since fetching the ```posts``` is expencive Elasticbone will delay it until a ```get``` is called to retreive them.
This uses jquery promises, so that you can register when a callback is fired.
When ```user.get('posts')``` a promise is returned for the posts that are fetched out of elasticsearch using the 
```fetch_query```. This query returns all posts where the field ```author``` is exactly the users name.


###Note: Circular has
A problem occurs when a model wants to have reverse relations, e.g. a user has posts, and a post has a user.

As javascript will execute in order THIS CODE WILL NOT WORK, because when User references posts it will not exist yet.

```
class User extends Elasticbone.ElasticModel
  @has 'posts', Posts

class Posts extends Elasticbone.ElasticCollection
  @has 'author', User 
```

Instead you can use ```has``` after the classes declaration

```
class User extends Elasticbone.ElasticModel

class Posts extends Elasticbone.ElasticCollection
  @has 'author', User

User.has 'posts', Posts

```

##Development

Installation: npm inst
Testing: npm test
Contribution: Welcome

##Production release

Aimed support for

1. has_one parse and fetch queries
2. has_many parse and fetch queries
3. Geographic Queries

