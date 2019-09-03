FROM ruby:2.5

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle lock --add-platform x86_64-linux
RUN bundle install

VOLUME [ "/app" ]

CMD ["rake ci:spec"]