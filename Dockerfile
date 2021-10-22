# # Select ubuntu as the base image
FROM ubuntu:16.04

# Install essential Linux packages
RUN apt-get update -qq && apt-get install -y git ruby2.3 ruby-dev tzdata build-essential libpq-dev postgresql-client nodejs imagemagick ffmpeg

# Define where our application will live inside the image
ENV RAILS_ROOT /var/www/consul

# Create application home. App server will need the pids dir so just create everything in one shot
RUN mkdir -p $RAILS_ROOT/tmp/pids

# Set our working directory inside the image
WORKDIR $RAILS_ROOT

# Use the Gemfiles as Docker cache markers. Always bundle before copying app src.
# (the src likely changed and we don't want to invalidate Docker's cache too early)
# http://ilikestuffblog.com/2014/01/06/how-to-skip-bundle-install-when-deploying-a-rails-app-to-docker/
COPY Gemfile Gemfile

COPY Gemfile.lock Gemfile.lock

COPY Gemfile_custom Gemfile_custom

# Prevent bundler warnings; ensure that the bundler version executed is >= that which created Gemfile.lock
#RUN gem install --default bundler -v 1.17.3

RUN gem install bundler --version '<= 1.16.5'

# Finish establishing our Ruby enviornment
RUN bundle install --full-index

# Copy the Rails application into place
COPY . .

# Define the script we want run once the container boots
# Use the "exec" form of CMD so our script shuts down gracefully on SIGTERM (i.e. `docker stop`)
#CMD [ "config/containers/app_cmd.sh" ]
#CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

RUN chmod +x entrypoint.sh

CMD [ "./entrypoint.sh" ]
