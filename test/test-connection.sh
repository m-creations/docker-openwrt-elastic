#!/bin/sh

# Sometimes health tests should be repeated (especially if this is ran right after the containers come up).

echo "first health test:"
curl http://127.0.0.1:9200/_cat/health

sleep 4 
echo "second health test:"
curl http://127.0.0.1:9200/_cat/health

sleep 3 
echo "third health test:"
curl http://127.0.0.1:9200/_cat/health

echo "Indices:"
curl http://localhost:9200/_cat/indices
