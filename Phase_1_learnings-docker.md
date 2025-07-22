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

```
docker run -it --rm \
  -v $(pwd)/htdocs:/usr/local/apache2/htdocs \
  -v $(pwd)/my-config/httpd.conf:/usr/local/apache2/conf/httpd.conf \
  aem-dispatcher-learning sh
```

Added to my httpd.conf

```
Include conf/vhosts/*.conf
```
build 
```
docker build -t aem-dispatcher-learning .
```

checked syntax 

```
docker run -it --rm \
  -v $(pwd)/htdocs:/usr/local/apache2/htdocs \
  -v $(pwd)/my-config/httpd.conf:/usr/local/apache2/conf/httpd.conf \
  -v $(pwd)/vhosts:/usr/local/apache2/conf/vhosts \
  aem-dispatcher-learning httpd -t
```

started container 
```
docker run -p 8080:80 \
  -v $(pwd)/htdocs:/usr/local/apache2/htdocs \
  -v $(pwd)/my-config/httpd.conf:/usr/local/apache2/conf/httpd.conf \
  -v $(pwd)/vhosts:/usr/local/apache2/conf/vhosts \
  aem-dispatcher-learning
```

```
curl -H "Host: example.com" http://localhost:8080
<h1>Public Site</h1>
```


```
docker ps
docker exec -it <container-name-or-id> sh
httpd -S
apachectl -S
```

```
docker run -it --rm \
  -v $(pwd)/htdocs:/usr/local/apache2/htdocs \
  -v $(pwd)/my-config/httpd.conf:/usr/local/apache2/conf/httpd.conf \
  -v $(pwd)/vhosts:/usr/local/apache2/conf/vhosts \
  aem-dispatcher-learning sh
```
