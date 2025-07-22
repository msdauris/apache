# Understanding Apache Virtual Host Files for AEM

## What Are Virtual Hosts?

Virtual Hosts allow **one Apache server** to serve **multiple websites** with different domain names. Each virtual host can have its own:
- Domain name (ServerName)
- Content directory (DocumentRoot) 
- Security rules
- Logging configuration

Think of it like having multiple websites on one physical server.

---

## Virtual Host #1: default.conf (The Catch-All)

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

### Line-by-Line Breakdown:

**`<VirtualHost *:80>`**
- Creates a virtual host that listens on port 80
- `*` means "accept requests from any IP address"
- This is the container for all the configuration

**`ServerName localhost`**
- This virtual host responds to requests for "localhost"
- When you visit `http://localhost:8080`, this virtual host handles it
- In production, this might be `internal.company.com` or similar

**`ServerAlias`**
- This lets the same virtual host respond to additional domain names or subdomains.
- Handles www.example.com, blog.example.com, etc.
- Useful for redirects, subdomains, or alternate URLs.

**`DocumentRoot /usr/local/apache2/htdocs`**
- The root directory where files are served from
- When someone requests `/index.html`, Apache looks in `/usr/local/apache2/htdocs/index.html`
- This maps to your local `htdocs/index.html` file

**Security Headers:**
```apache
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-Content-Type-Options "nosniff"
```
- `X-Frame-Options "SAMEORIGIN"` = Prevents your site from being embedded in iframes from other domains
- `X-Content-Type-Options "nosniff"` = Prevents browsers from guessing file types (security feature)
- **AEM requires these headers** for security compliance

**Directory Block:**
```apache
<Directory "/usr/local/apache2/htdocs">
    Options -Indexes          # Don't show directory listings
    AllowOverride None        # Don't allow .htaccess files
    Require all granted       # Allow everyone to access
</Directory>
```

### Purpose: 
This is your **fallback/default** virtual host - catches any requests that don't match other virtual hosts.

---

## Virtual Host #2: public.conf (The Public Website)

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

### Key Differences from default.conf:

**`ServerName example.com`**
- This virtual host responds to requests for "example.com"
- In production, this would be your actual domain like `mycompany.com`

**`DocumentRoot /usr/local/apache2/htdocs/public`**
- Serves files from a **different directory** than the default
- Maps to your local `htdocs/public/` folder
- Shows how different domains can serve different content

**Additional Security Header:**
```apache
Header always set Referrer-Policy "strict-origin-when-cross-origin"
```
- Controls how much referrer information is sent with requests
- **AEM best practice** for privacy and security

**AEM Dispatcher Security Rules:**
```apache
RewriteEngine On

# Block access to sensitive paths
RewriteRule ^/apps - [F,L]      # Block AEM component code
RewriteRule ^/bin - [F,L]       # Block AEM servlets
RewriteRule ^/crx - [F,L]       # Block CRX repository access
RewriteRule ^/system - [F,L]    # Block system paths
```

**What These Rules Mean:**
- `^/apps` = Any URL starting with `/apps`
- `[F,L]` = **F**orbidden (return 403 error), **L**ast rule (stop processing)
- These paths contain **sensitive AEM internals** that should never be accessible from the internet

**Allow Specific Content:**
```apache
RewriteRule ^/content/(.*)$ /content/$1 [L]
RewriteRule ^/etc.clientlibs/(.*)$ /etc.clientlibs/$1 [L]
```
- `/content/` = Where AEM stores website pages
- `/etc.clientlibs/` = Where AEM stores CSS/JavaScript files
- `(.*)` = Capture everything after the path
- `$1` = Use what was captured
- These are the **safe paths** that can be accessed publicly

---

## How They Work Together

### Request Flow:

1. **Request comes in:** `http://localhost:8080/`
   - Apache checks ServerName
   - Matches `localhost` → Uses **default.conf**
   - Serves from `/usr/local/apache2/htdocs/index.html`

2. **Request comes in:** `http://example.com:8080/`
   - Apache checks ServerName
   - Matches `example.com` → Uses **public.conf**
   - Serves from `/usr/local/apache2/htdocs/public/index.html`

### Security Differences:

**default.conf** = Basic security (internal/admin access)
**public.conf** = Enhanced security (public website)

The public virtual host has **stricter security rules** because it faces the internet.

---

## Real-World AEM Equivalent

In production AEM, you might have:

```apache
# Author environment (internal only)
<VirtualHost *:80>
    ServerName author.mycompany.com
    # Less restrictive - authors need access to /apps, /bin, etc.
</VirtualHost>

# Publish environment (public-facing)
<VirtualHost *:80>
    ServerName www.mycompany.com
    # Very restrictive - block all AEM internals
    RewriteRule ^/apps - [F,L]
    RewriteRule ^/bin - [F,L]
    # etc.
</VirtualHost>
```

### Key Takeaways:

1. **Virtual hosts separate concerns** - different domains, different rules
2. **Security layers** - public sites need more protection than internal tools
3. **AEM-specific patterns** - blocking sensitive paths, allowing content paths
4. **Directory structure** - different domains can serve from different folders

This foundation will help you understand how the YAML-to-config generation works - it's creating these virtual host patterns automatically based on your requirements!