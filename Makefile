.PHONY: test-setup test

TEST_DIR := test

test-setup:
	(cd $(TEST_DIR) && gem install bundler && bundle install)

test:
	cd $(TEST_DIR) && bundle exec rspec *.rb
