SHELL := /bin/bash
MD_ACCESS_TOKEN := $(shell curl --silent --location 'https://api.mobilitydatabase.org/v1/tokens' --header 'Content-Type: application/json' --data '{ "refresh_token": "$(MD_REFRESH_TOKEN)" }' | jq -r '.access_token')

feeds:
	curl --silent --location 'https://api.mobilitydatabase.org/v1/feeds' --header 'Authorization: Bearer $(MD_ACCESS_TOKEN)' | jq . > feeds.json

gtfs_feeds:
	curl --silent --location 'https://api.mobilitydatabase.org/v1/gtfs_feeds' --header 'Authorization: Bearer $(MD_ACCESS_TOKEN)' | jq . > gtfs_feeds.json

default: 
	@echo $(MD_ACCESS_TOKEN)

jsons:
	jq '.[].latest_dataset.hosted_url | if . != null then . else empty end' gtfs_feeds.json | \
	ruby jsons.rb;
	tippecanoe -f -o a.mbtiles --drop-densest-as-needed a.jsons;
	pmtiles convert a.mbtiles a.pmtiles

