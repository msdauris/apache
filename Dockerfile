FROM httpd:2.4-alpine
COPY ./htdocs/ /usr/local/apache2/htdocs/

# Install necessary packages
RUN apk add --no-cache \
    apache2-dev \
    gcc \
    make \
    musl-dev \
    curl

# Copy custom Apache configuration
COPY httpd.conf /usr/local/apache2/conf/httpd.conf

# Create directories for dispatcher configs
RUN mkdir -p /usr/local/apache2/conf/dispatcher
RUN mkdir -p /usr/local/apache2/conf/vhosts

# Copy vhost files (we'll create these)
COPY vhosts/ /usr/local/apache2/conf/vhosts/

# Expose port 80
EXPOSE 80

CMD ["httpd-foreground"]
