.PHONY: test lint setup server console

test:
	bundle exec rspec

lint:
	bundle exec rubocop

setup:
	bundle install
	cp -n .env.example .env || true
	rails db:create db:migrate

server:
	rails server

console:
	rails console
