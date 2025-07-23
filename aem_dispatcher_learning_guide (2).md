# AEM Dispatcher Learning Guide - Docker Setup & Project Steps

## Phase 1: Understanding AEM Dispatcher with Docker

### Prerequisites
- Docker installed on your machine
- Basic understanding of Apache configuration
- Text editor (VS Code, nano, etc.)

### Step 1: Create Docker Environment

Create a new directory for your learning environment:
```bash
mkdir aem-dispatcher-learning
cd aem-dispatcher-learning
```

### Step 2: Create Dockerfile for Apache

Create a `Dockerfile`:
```dockerfile
FROM httpd:2.4-alpine

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
```

### Step 3: Create Basic Apache Configuration

Create `httpd.conf`:
```apache
ServerRoot "/usr/local/apache2"
Listen 80

LoadModule mpm_event_module modules/mod_mpm_event.so
LoadModule authz_core_module modules/mod_authz_core.so
LoadModule dir_module modules/mod_dir.so
LoadModule mime_module modules/mod_mime.so
LoadModule rewrite_module modules/mod_rewrite.so
LoadModule alias_module modules/mod_alias.so
LoadModule headers_module modules/mod_headers.so
LoadModule log_config_module modules/mod_log_config.so

ServerName localhost:80
DirectoryIndex index.html

# Basic security
<Directory />
    AllowOverride none
    Require all denied
</Directory>

<Directory "/usr/local/apache2/htdocs">
    AllowOverride None
    Require all granted
</Directory>

# Include vhost configurations
Include conf/vhosts/*.conf

# Basic mime types
TypesConfig conf/mime.types
```

### Step 4: Create Sample VHost Files

Create `vhosts/` directory and sample files:

**vhosts/default.conf** (similar to AEM's default.vhost):
```apache
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /usr/local/apache2/htdocs
    
    # Basic logging
    ErrorLog logs/default_error.log
    CustomLog logs/default_access.log combined
    
    # Security headers (AEM pattern)
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    
    # Basic directory configuration
    <Directory "/usr/local/apache2/htdocs">
        Options -Indexes
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>
```

**vhosts/public.conf** (similar to AEM's public.vhost):
```apache
<VirtualHost *:80>
    ServerName example.com
    DocumentRoot /usr/local/apache2/htdocs/public
    
    # Logging
    ErrorLog logs/public_error.log
    CustomLog logs/public_access.log combined
    
    # AEM-style security headers
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    
    # AEM dispatcher-style rules
    RewriteEngine On
    
    # Block access to sensitive paths
    RewriteRule ^/apps - [F,L]
    RewriteRule ^/bin - [F,L]
    RewriteRule ^/crx - [F,L]
    RewriteRule ^/system - [F,L]
    
    # Allow specific content paths
    RewriteRule ^/content/(.*)$ /content/$1 [L]
    RewriteRule ^/etc.clientlibs/(.*)$ /etc.clientlibs/$1 [L]
    
    <Directory "/usr/local/apache2/htdocs/public">
        Options -Indexes
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>
```

### Step 5: Build and Run Docker Container

### Step 5A: Create Sample Content Structure

**Understanding the Directory Structure:**

```bash
mkdir -p htdocs/public
```

This creates a nested directory structure:
```
aem-dispatcher-learning/
├── htdocs/                    # Main document root
│   ├── index.html            # Default site homepage
│   └── public/               # Public site subdirectory
│       └── index.html        # Public site homepage
```

**Why This Structure?**
- `htdocs/` = Apache's main document root (like `/var/www/html`)
- `htdocs/public/` = Separate directory for the "public" virtual host
- This mimics how AEM separates different sites/domains

**Creating the Content Files:**

```bash
echo "<h1>Default Apache Page</h1>" > htdocs/index.html
```
- Creates a simple HTML file in the main document root
- The `>` operator writes content to a file (creates or overwrites)
- This file will be served when you visit `http://localhost:8080`

```bash
echo "<h1>Public Site</h1>" > htdocs/public/index.html
```
- Creates a different HTML file in the public subdirectory
- This file will be served by the "public.conf" virtual host
- Shows how different domains can serve different content

**The Connection to Virtual Hosts:**

In your virtual host files:

**default.conf** points to:
```apache
DocumentRoot /usr/local/apache2/htdocs
```
↳ Serves `htdocs/index.html` → Shows "Default Apache Page"

**public.conf** points to:
```apache
DocumentRoot /usr/local/apache2/htdocs/public
```
↳ Serves `htdocs/public/index.html` → Shows "Public Site"

**What You'll See When Testing:**
- `http://localhost:8080` → "Default Apache Page"
- `http://example.com:8080` → "Public Site" (if you add to hosts file)

**Real-World AEM Equivalent:**
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

This simple structure helps you understand how different domains serve different content from different directories.

Build and run:
```bash
docker build -t aem-dispatcher-learning .
docker run -p 8080:80 -v $(pwd)/htdocs:/usr/local/apache2/htdocs aem-dispatcher-learning
```

### Step 6: Test Your Setup

Open browser and test:
- http://localhost:8080 (should show default page)
- Try adding `example.com` to your `/etc/hosts` file pointing to 127.0.0.1

### Step 7: Examine Configuration Files

Use `docker exec` to examine running container:
```bash
docker exec -it <container_id> /bin/sh
cd /usr/local/apache2/conf
ls -la
cat vhosts/default.conf
```

---

---

## Updated Workflow Based on Team Feedback

### New Approach: Start with Real Working Configs

Your colleague suggests a **reverse-engineering approach** which is actually smarter for learning:

**Old Approach (what we planned):**
1. Learn Apache basics → Build Maven → Generate configs

**New Approach (colleague's suggestion):**
1. **Get working configs** → Understand them → **Then** build automation

---

## Phase 1: Get Real Working Configs (Week 1)

### Step 1: Copy Production Dispatcher Configs
```bash
# Get configs from a working environment
scp user@prod-server:/etc/apache2/sites-available/* ./existing-configs/
# Or however you access your current configs
```

### Step 2: Set Up Local Docker Environment
Use the same Docker setup, but now copy your **real configs** instead of sample ones:

```bash
# Copy your real configs to vhosts/
cp existing-configs/*.conf vhosts/
```

### Step 3: Make Configs Work Locally
**Goal**: Get your production configs running in Docker

**Common changes needed:**
- Change `ServerName` from prod domains to `localhost`
- Update file paths from `/var/www/` to `/usr/local/apache2/htdocs/`
- Comment out modules you don't have locally
- Adjust log paths

**Example transformation:**
```apache
# Production config:
ServerName mysite.prod.com
DocumentRoot /var/www/html/mysite
ErrorLog /var/log/apache2/mysite_error.log

# Local Docker version:
ServerName localhost
DocumentRoot /usr/local/apache2/htdocs/mysite
ErrorLog logs/mysite_error.log
```

---

## Phase 2: Identify Requirements (Week 2)

### Step 4: Document Environment Differences
Create a spreadsheet/document tracking:

**File Path Differences:**
- Dev: `/opt/adobe/dispatcher/cache/`
- Stage: `/mnt/cache/dispatcher/`
- Prod: `/data/dispatcher/cache/`

**Hostname Differences:**
- Dev: `mysite.dev.company.com`
- Stage: `mysite.stage.company.com`
- Prod: `mysite.company.com`

**Server Role Differences:**
- Author servers: Different security rules
- Publish servers: Different caching rules
- Dispatcher servers: Different upstream configs

### Step 5: Identify Templating Needs
**What needs to be variable:**
- `${ENVIRONMENT}` → dev, stage, prod
- `${DOMAIN_SUFFIX}` → .dev.company.com, .stage.company.com, .company.com
- `${CACHE_ROOT}` → different paths per environment
- `${BACKEND_HOST}` → different AEM instances

**Example template pattern:**
```apache
ServerName mysite.${ENVIRONMENT}.company.com
DocumentRoot ${CACHE_ROOT}/mysite
ProxyPass /content/ http://${BACKEND_HOST}:4503/content/
```

---

## Phase 3: Maven Package Development (Week 3-4)

### Step 6: Understand Current Maven Project
Now that you understand the **requirements**, examine how the Maven project works:

```bash
cd aem-project-infra-dispatcher
mvn clean install
# Now you understand what this SHOULD generate
```

### Step 7: Compare Generated vs Real Configs
**Key questions:**
- Does the generated config match your real config patterns?
- Are all your identified variables handled?
- Does it support all your server roles?

### Step 8: Refactor Maven Project
Based on your findings:
- Update YAML schema to support your requirements
- Modify templates to match your patterns
- Add validation for cross-platform compatibility

---

## Updated Success Criteria

### Week 1 Success:
- [ ] Real production configs copied locally
- [ ] Configs work in Docker environment
- [ ] Can serve content locally

### Week 2 Success:
- [ ] All environment differences documented
- [ ] Variable requirements identified
- [ ] Template patterns defined

### Week 3-4 Success:
- [ ] Maven generates configs matching your patterns
- [ ] Single package deployable to all environments
- [ ] Cross-platform validation working

---

## Why This Approach is Better

### For Learning:
- You see **real complexity** upfront
- Understand **actual requirements** vs theoretical ones
- Learn by **reverse-engineering** working systems

### For Implementation:
- Less risk of missing requirements
- Generated configs will actually work
- Team alignment on real-world needs

### For Your Junior Level:
- Start with **concrete examples** vs abstract concepts
- See the **destination** before building the journey
- Less overwhelming than starting from scratch

---

## Updated Docker Learning Focus

Instead of learning basic Apache, you're now learning:
1. **How your actual configs work**
2. **What makes them environment-specific**
3. **How to template them for automation**

This is much more valuable for your actual project!

### Week 1: Foundation Setup
**Goal**: Get Maven build working and understand generated configs

#### Step 1: Maven Build Setup
```bash
cd aem-project-infra-dispatcher
mvn clean install
```

**Expected Outcome**: 
- `.generator/` folder created with build scripts
- `target/` folder with generated configurations
- Framework structure established

#### Step 2: Examine Generated Structure
```bash
ls -la .generator/
ls -la target/
```

**Learning Focus**: 
- Understand what Maven generates
- Compare with your Docker Apache setup
- Identify key differences

#### Step 3: Initial Configuration
Edit `.generator/env.js`:
```javascript
// Start with minimal environments
mapDirName: [ 'dev', 'stage', 'prod' ],
projectName: ['your-project-name'],
```

### Week 2: First Domain Configuration
**Goal**: Generate configs for one domain and test

#### Step 4: Create First YAML File
```bash
mkdir -p resources/your-project-name
```

Create `resources/your-project-name/example.com.yml`:
```yaml
name: example.com
www: yes
tenant: example
sites:
  - path: example
    languages:
      - 'en'
enabled: yes
multiSite: no
multiLanguage: no
rootHomepage: yes
addRootRedirect: yes
```

#### Step 5: Generate Configuration
```bash
cd .generator
node build.js
```

#### Step 6: Compare Generated vs Manual
- Compare generated `target/` configs with your Docker setup
- Identify AEM-specific patterns
- Document differences

### Week 3: Testing & Validation
**Goal**: Validate generated configs work

#### Step 7: Test Generated Configs
- Copy generated configs to your Docker environment
- Test functionality
- Debug any issues

#### Step 8: Add More Environments
Gradually add more environments to `env.js`:
```javascript
mapDirName: [ 'dev', 'dev2', 'stage', 'prod' ],
```

### Week 4: Scale & Documentation
**Goal**: Full implementation and team handoff

#### Step 9: Complete Environment List
Add all your environments:
```javascript
mapDirName: [ 
  'dev', 'dev2', 'dev3', 'dev4',
  'qa1', 'qa2', 
  'stage', 'stage-preview',
  'prod', 'prod-preview'
],
```

#### Step 10: Document Process
- Create team documentation
- Document troubleshooting steps
- Create deployment procedures

---

## Key Learning Points

### What You'll Understand After Docker Phase:
1. **Basic Apache VHost structure**
2. **AEM security patterns** (blocking /apps, /bin, etc.)
3. **Header configurations** for security
4. **Rewrite rules** for content routing
5. **Directory permissions** and access control

### What You'll Understand After Maven Phase:
1. **How YAML translates to Apache config**
2. **AEM Cloud Service requirements**
3. **Multi-environment configuration patterns**
4. **Dispatcher-specific optimizations**

### Success Criteria:
- [ ] Docker Apache runs successfully
- [ ] Can manually create basic VHost files
- [ ] Maven build completes without errors
- [ ] Can generate configs from YAML
- [ ] Generated configs work in Docker environment
- [ ] Team can replicate the process

---

---

## Troubleshooting Quick Reference

### Docker Issues:

**"This site can't be reached" on port 8080:**

**Step 1: Check if containers are actually running**
```bash
docker ps
```
Look for STATUS = "Up" and PORT = "0.0.0.0:8080->80/tcp"

**Step 2: Check for port conflicts (multiple containers)**
```bash
docker ps -a
# Stop all containers using port 8080
docker stop $(docker ps -q --filter "publish=8080")
```

**Step 3: Check container logs**
```bash
docker logs <container_id>
```
Look for Apache startup errors or configuration issues

**Step 4: Test with different port**
```bash
docker run -p 8081:80 -v $(pwd)/htdocs:/usr/local/apache2/htdocs aem-dispatcher-learning
```

**Step 5: Verify Apache is running inside container**
```bash
docker exec -it <container_id> /bin/sh
ps aux | grep httpd
netstat -tlnp | grep :80
```

**Step 6: Test basic connectivity**
```bash
curl http://localhost:8080
# Or try from inside container:
docker exec -it <container_id> curl http://localhost
```

### Common Issues:
- **Multiple containers on same port**: Only one can bind to 8080
- **Configuration syntax errors**: Check Apache logs
- **File permission issues**: Check volume mount permissions
- **Service not starting**: Apache config errors prevent startup

### Quick Cleanup Commands:
```bash
# Stop all running containers
docker stop $(docker ps -q)

# Remove all containers (running and stopped)
docker rm $(docker ps -aq)

# Remove the image to start fresh tomorrow
docker rmi aem-dispatcher-learning
```

### Safe Daily Cleanup Process:

**Yes, you can absolutely delete containers when done for the day!**

**Option 1: Docker Desktop GUI**
- Open Docker Desktop
- Go to "Containers" tab
- Click trash icon next to each container
- Go to "Images" tab  
- Delete "aem-dispatcher-learning" image if you want to rebuild fresh

**Option 2: Command Line Cleanup**
```bash
# Stop everything
docker stop $(docker ps -q)

# Remove all containers
docker rm $(docker ps -aq)

# Remove your custom image (optional - rebuilds tomorrow)
docker rmi aem-dispatcher-learning

# Nuclear option - remove everything Docker related
docker system prune -a
```

**What Gets Preserved:**
- Your project files (Dockerfile, httpd.conf, vhosts/, etc.)
- Your learning progress
- All the code in your directory

**What Gets Deleted:**
- Running containers (temporary anyway)
- Built Docker images (you can rebuild with `docker build`)
- Any temporary data inside containers

**Tomorrow Morning Process:**
1. `docker build -t aem-dispatcher-learning .`
2. `docker run -p 8080:80 -v $(pwd)/htdocs:/usr/local/apache2/htdocs aem-dispatcher-learning`
3. Fresh start with morning brain! ☕

### Maven Issues:
- Port conflicts: Use different port `-p 8081:80`
- Permission issues: Check file ownership
- Config errors: Check Apache error logs

### Maven Issues:
- Java version: Ensure Java 8 or 11
- Network issues: Check proxy settings
- Missing dependencies: Run `mvn clean install` again

### Generation Issues:
- YAML syntax: Validate YAML format
- Path issues: Check file locations
- Environment names: Ensure consistency