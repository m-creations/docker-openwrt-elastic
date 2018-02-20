#!/bin/sh

# create a new index while posting a message to it:

curl -XPUT 'localhost:9200/foo/tweet/1?pretty' -H 'Content-Type: application/json' -d'
{
    "user" : "kimchy",
    "post_date" : "2009-11-15T14:12:12",
    "message" : "trying out Elasticsearch"
}
'

# query for this index:

curl -XGET 'localhost:9200/twitter/tweet/1?pretty'


# post a second message to the index:


curl -XPUT 'localhost:9200/foo/tweet/2?pretty' -H 'Content-Type: application/json' -d'
{
    "title" : "Search",
    "publish_date" : "2017-11-15",
    "content" : "trying out Elasticsearch",
    "status" : "published"
}
'

# send a query on this index to get only the second message:

echo "Query test:"

curl -XGET 'localhost:9200/_search?pretty' -H 'Content-Type: application/json' -d'
{
  "query": { 
    "bool": { 
      "must": [
        { "match": { "title":   "Search"        }}, 
        { "match": { "content": "Elasticsearch" }}  
      ],
      "filter": [ 
        { "term":  { "status": "published" }}, 
        { "range": { "publish_date": { "gte": "2015-01-01" }}} 
      ]
    }
  }
}
'
