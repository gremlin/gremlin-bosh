.PHONY: test-setup test

TEST_DIR := test

tile-setup:
	python3 -m pip install -r .circleci/scripts/requirements.txt

tile-build:
	tile build

test-setup:
	(cd $(TEST_DIR) && gem install bundler && bundle install)

test:
	cd $(TEST_DIR) && bundle exec rspec *.rb
