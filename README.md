# Apache AEM Dispatcher Learning Notes

## Project Structure

### Basic Learning Structure
```
aem-dispatcher-learning/
├── htdocs/                    # Main document root
│   ├── index.html            # Default site homepage
│   └── public/               # Public site subdirectory
│       └── index.html        # Public site homepage
```

### Real-World AEM Equivalent
```
/var/www/html/
├── content/
│   ├── mysite/
│   │   └── en/
│   │       └── index.html
│   └── anothersite/
│       └── en/
│           └── index.html
└── etc.clientlibs/
    └── [CSS/JS files]
```

### Configuration Structure
```
project-root/
├── htdocs/
│   ├── index.html
│   └── public/
│       └── index.html
├── my-config/
│   └── httpd.conf  <-- you're editing this one!
```

## Sample HTML Files

### index.html
```html
<h1>Default Apache Page</h1>
```

### public/index.html
```html
<h1>Public Site</h1>
```

## Docker Commands

### Core Operations

| Task                     | Command                                                                                                                                                      |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Build image              | `docker build -t aem-dispatcher-learning .`                                                                                                                  |
| Run default config       | `docker run -p 8080:80 -v $(pwd)/htdocs:/usr/local/apache2/htdocs aem-dispatcher-learning`                                                                   |
| Run with custom config   | `docker run -p 8080:80 -v $(pwd)/htdocs:/usr/local/apache2/htdocs -v $(pwd)/my-config/httpd.conf:/usr/local/apache2/conf/httpd.conf aem-dispatcher-learning` |
| Get default `httpd.conf` | `docker run --rm httpd:2.4 cat /usr/local/apache2/conf/httpd.conf > my-config/httpd.conf`                                                                    |
| Start Apache manually    | `httpd-foreground` (inside container)                                                                                                                        |

### Container Shell Access

Enter container shell before launching:
```bash
docker run -it --rm \
  -v $(pwd)/htdocs:/usr/local/apache2/htdocs \
  aem-dispatcher-learning sh
```

Access running container:
```bash
docker ps
docker exec -it <container-name or container-id> sh
# Example: docker exec -it my-apache sh
```

### Container Debugging

Check if files are visible:
```bash
ls /usr/local/apache2/htdocs
ls /usr/local/apache2/htdocs/public
```

Manually start Apache:
```bash
httpd-foreground
```

Check Apache configuration:
```bash
httpd -t
```

View configuration file:
```bash
cat /usr/local/apache2/conf/httpd.conf
```

### Cleanup Commands

Remove all containers and images:
```bash
docker rm -f $(docker ps -aq)
docker rmi -f aem-dispatcher-learning
```

## Docker Command Reference

### Key Command Differences

- `exec` = run a command inside a running container
- `run` = start a new container
- `-it` = interactive + terminal (you want both)
- `--rm` = remove the container after exit (safe for debugging)

### Interactive Shell Session
```bash
docker run -it --rm \
  -v $(pwd)/htdocs:/usr/local/apache2/htdocs \
  aem-dispatcher-learning sh
```

This command starts a new container with:
- Interactive terminal access
- Auto-removal when you exit
- Volume mounted for your HTML files
- Shell access for debugging
