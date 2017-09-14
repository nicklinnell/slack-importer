FROM ruby:latest

ENV APP_DIR /app
RUN mkdir -p $APP_DIR
WORKDIR $APP_DIR

ADD Gemfile* $APP_DIR/
RUN bundle install

CMD ['ruby', 'importer.rb']
