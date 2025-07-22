#Minimal viable config for static HTML hosting via Docker:

LoadModule mpm_event_module modules/mod_mpm_event.so
LoadModule unixd_module modules/mod_unixd.so
LoadModule dir_module modules/mod_dir.so
LoadModule mime_module modules/mod_mime.so
LoadModule authz_core_module modules/mod_authz_core.so
LoadModule log_config_module modules/mod_log_config.so

Add these if you're using:
mod_rewrite.so → rewrites
mod_alias.so → alias paths
mod_headers.so → custom headers (e.g., CSP, CORS)


If you want to check inside the running container directly:
Run an interactive shell inside your container with the config file accessible:

````
docker run -it --rm \
  -v $(pwd)/htdocs:/usr/local/apache2/htdocs \
  -v $(pwd)/my-config/httpd.conf:/usr/local/apache2/conf/httpd.conf \
  aem-dispatcher-learning sh
````