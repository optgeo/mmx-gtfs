SHELL := /bin/bash
MD_ACCESS_TOKEN := $(shell curl --silent --location 'https://api.mobilitydatabase.org/v1/tokens' --header 'Content-Type: application/json' --data '{ "refresh_token": "$(MD_REFRESH_TOKEN)" }' | jq -r '.access_token')

feeds:
	curl --silent --location 'https://api.mobilitydatabase.org/v1/feeds' --header 'Authorization: Bearer $(MD_ACCESS_TOKEN)' | jq . > feeds.json

default: 
	@echo $(MD_ACCESS_TOKEN)