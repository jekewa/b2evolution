# B2EVOLUTION

A b2evolution.net installation on Apache v2.4 with PHP 7.4.
This evolved after the Ubuntu 21.10 update removed the php7.4 package, and rendered the b2evolution software unusable because of the removal of previously deprecated functions.

Outlined in this blog post https://fplanque.com/dev/b2evolution/18-years-of-b2evolution, continued development of the b2evolution software isn't going to happen unless someone else takes the mantle.
This isn't taking that mantle.
This does provide continued running software in spite of OS choices until that software is updated, or a replacement is found.

## Expected Container Location

The source for building the container should be found at https://github.com/jekewa/b2evolution.

The container should be available on the Docker Hub at https://hub.docker.com/repository/docker/jekewa/b2evolution. 
This allows loading as `jekewa/b2evolution` if the Docker Hub repository is used (which it is normally by default).

The container should be available on the GithHub Repository at https://ghcr.io/repository/docker/jekewa/b2evolution. 
This allows loading as `ghcr.io/jekewa/b2evoluion`.

The SSL with Let's Encrypt is also built and available at both of those locations.
This will come with the additional Apache VirtualHost configuration for accepting SSL sockets, and configuring the certificates.
This is discussed below.
This requires simply adding `ssl-` to the tag, such as `jekewa/b2evolution:ssl-latest`.

## Running the Container

This container can be used "out of the box" by providing the necessary variables and volumes, discussed below, and running the container.

```
docker run --name b2evolution -p 80:80 -p 443:443 -v /etc/letsencrypt:/etc/letsencrypt -v b2evolution-cache:/opt/b2evolution/_cache -v b2evolution-media --env-file sample.env --add-host mysql:10.10.10.10 jekewa/b2evolution
```

This will start the default b2evolution as if unpacked in an Apache folder with minimal configuration.
Some notes follow about the installation; this is expected to be a running system, as if following an installation.
This container doesn't "out of the box" allow the installer to be run.

Clearly, some of the details will be different on each deployment.
Using volumes or mounts, and the names will surely vary based on local configurations.
Using a local file or container-managed values, or naming each individually are options expected to be different.
The hostname and IP need to match the local configuration and network.
And changing the name of the container or image as necessary based on how it was received, or otherwise desired.

# Required Variables

For transportability, the few required and varying bits of the Apache and b2evolution configuration have been made to read environment variables that are passed through Docker when starting the container. 
These need to be set in Docker container managment tools or at the Docker command line.

To prevent faillures running the container, these all have defaults in the Dockerfile.
This will certainly lead to failure running the application, as the configuration won't make sense to real environments.

These are the minimum required variables to get the Apache and b2evolution to run as expected.

- `SERVER_NAME` - the FQDN of the Apache server. 
This would be "example.com" or "www.example.com" with the right name.
- `PHP_TIMEZONE` - the name of the time zone to associate with the blog. 
See https://www.php.net/manual/en/timezones.php for acceptable entries.
- `BASE_URL` - the URL b2evolution will use by default.
This should be the URL before any other path elements, such as `https://www.example.com/`, but with the real domain.
- `ADMIN_EMAIL` - the default admin user e-mail.
- `DB_USER` - the username configured for the MySQL server
- `DB_PASSWORD` - the password for the MySQL user
- `DB_NAME` - the name of the database to use on the MySQL server
- `DB_SERVER` - the hostname of the MySQL server

There is an SSL configuration that works with Let's Encrypt.
By default, SSL is not enabled unless using the ssl-prefixed tags.
Adding this variable is required to name Let's Encrypt certificate files to be used.
Additionally, be sure to add the volume to reach the /etc/letsencrypt files.

- `LETSENCRYPT_CERTNAME` - the *CERTNAME* part in the path on /etc/letsencrypt/live/CERTNAME that leads to the current PEM files.

As called out in the b2evolution documentation, the software can be used at other paths than the root.
To facilitate this, an optional variable can be provided to associate the deeper path.
Ideally, this should match the path in the `BASE_URL` variable.

- `ALIAS` - the slash-terminated path to include as an alias.
This should be in proper URL path format, starting and ending with slashes, such as `/deep/path/`.

This will allow reaching the b2evolution app at both the root and alias.
Ideally, this matches the BASE_URL parameter, the responses should redirect to the alias.
That is, if `BASE_URL` is `http://example.com/deep/path/`, the `ALIAS` should be `/deep/path/`.

As this is not required, this value is not in the Dockerfile or sample.env.

All of the values could be added via the command-line, an environment file, or in a container management system.

## Command-line Example

The variables can be provided at the command line like this:

```
docker run --name b2evolution ... -e SERVER_NAME=mydomain.info ... -e DB_SERVER=mysql ... jekewa/b2evolution
```

## Environment File Example
An alternative is to add those variables to a file the Docker host can access, and provide that in the command line. 
This has the added benefit of keeping passwords off commandline histories and Docker views. 
For example, adding those to a file named /etc/b2evolution/env could be used in this command:

```
docker run --name b2evolution ... --env-file /etc/b2evolution/env ... jekewa/b2evolution
```

A `sample.env` file is provided to ensure all of the essential variables are easy to find.
Of course, edit this file with the correct values.

## Container Management

Docker container management tools have other mechanisms for adding these variables to the container.
This may include leveraging something like the sample.env file.
This could be building a Docker Compose file leveraging the container and providing the correct values, which can also be handy for providing a database at the same time.

## Baked-in Variables

If preferred, extend this Docker container and bake the variables into the build.

Create a new Dockerfile, leveraging this container, and add the variables.
Rebuild the container and deploy that container instead.
Examples are at the end of this README.

This satisfies immutibility, but compromises security.

# DB_SERVER - MySQL Host Name

The DB_SERVER should be DNS and network accessible from within the container. 
This could be another container in a Docker Compose or other container configuration.
Accessing this container will depend on the environment.

## Simple Network Access

This simply assumes a MySQL database server is running somewhere, configured independently.

Note that the b2evolution software doesn't make it apparent that one can change the MySQL port used for the database.
Because of this, the instructions and container assume MySQL is available at its default port of 3306.

If the MySQL server is at an address available by DNS, simply adding the DB_HOST value to the container will allow it to be reached.

If a DNS-available hostname isn't provided, add its IP to the Docker container using the add-host flag.
For example, if the MySQL server was hosted on the IP 10.10.10.10, the command would look thus:

```
docker run --name b2evolution ... -e DB_SERVER=mysql --add-host mysql:10.10.10.10 ... jekewa/b2evolution
```

Use the actual IP address, of course, and match the provided host name to the name passed in the variable.

# LETSENCRYPT_CERTNAME - Let's Encrypt

The container is built with an optional site using an externally managed Let's Encrypt. 
This could be something the host does, or perhaps a Let's Encrypt Docker container, with a volume mounted. In a simple discussion, use certbot to create and maintain certificates, including at least the one for CERTNAME, as used in the required variables.

As configured, it's expecting the full-chain PEM file and related key-file to be accessible in a subfolder in the mounted (not in the container) /etc/letsencrypt folder. 
This is because the /etc/letsencrypt "live" path folders eventually a symlink to a paOptimized kernel for cloud use at scalerent folder with an archive of the most recent set of PEM files, selecting the current to use as the live one. 
Using Let's Encrypt, assuming the files are accessible on the Docker host, mount the folder with  path volume such as this:

```
docker run --name b2evolution ... -e LETSENCRYPT_CERTNAME=example.com -v /etc/letsencrypt:/etc/letsencrypt ... jekewa/b2evolution
```

This expects that inside of the /etc/letsencrypt folder is a live folder, which inturn contains the `LETSENCRYPT_CERTNAME` folder.
This may or may not match the `SERVER_NAME`, depending on how the certbot created the certificates.
Inside of that folder should be the fullchain.pem and privkey.pem files, which are expected to be readable.
These are the files referenced in the Apache configuration.

To enable the SSL site, it's necessary to either rebuild the container enabling the site in the Dockerfile, or run a quick enable and reload on the container. Note that the latter requires this to happen each time the container is deployed (but not restarted).

After starting the container with the variable and volume, as above, hit it quick with these (or execute the commands in a connected share):

```
docker exec b2evolution a2ensite b2evolution-ssl
docker exec b2evolution apachectl graceful
```

Using apachectl instead of the service will allow the environment variables set in the running container to be reused.
After this, the SSL will be enabled in the container.

If this is going to be a frequent thing, extending the container with SSL would be better.
See the example below.

# Volumes - External Storage

There are a couple of folders in b2evolution that should remain bewteen deployments.
The `_cache` folder could contain a lot of data as a full or busy site builds a large cache.
The `media` folder could also contain a lot of data as things are uploaded to be shared.
If the _cache and media folders aren't mounted, storage inside the container will be used, but their contents will be lost with the container if it is destroyed or redeployed. 

To facilitate this, a few volumes are recommended, whether network shares or local file shares.
This will allow files to survive restarts and rebuilding of the container. 

Volume or storage management may also be part of your container system.

## Create Volume Example

```
docker create volume b2evolution-cache
docker create volume b2evolution-media
```

The create needs only be run once for each volume.
Subsequent runs, or even multiple containers running at the same time, can use the volumes.
This works well with NFS mounted shares, also.
See the Docker VOLUME documentation for details.

## Mount Example

This example shows how to leverage the Docker volumes with the --mount option:

```
docker run --name b2evolution ... --mount source=b2evolution-cache,destination=/opt/b2evolution/_cache --mount source=b2evolution-media,destination=/opt/b2evolution/media ... jekewa/b2evolution
```

## Voume Example

This example shows how to leverage the Docker volumes with the --volume or -v option:

```
docker run --name b2evolution ... --volume b2evolution-cache:/opt/b2evolution/_cache -v b2evolution-media:/opt/b2evolution/media ... jekewa/b2evolution
```

## Local Example

Alternatively use the --volume or -v option with local (to the Docker host) folders:

```
docker run --name b2evolution ... -v /path/cache:/opt/b2evolution/_cache -v /path/media:/opt/b2evolution/media ... jekewa/b2evolution
```

## Permissions

Note that the user in the container is `www-data:www-data`, the Apache default user.
If the contents of these folders belong to another user from a different installation, there may be permission issues that need to be resolved after starting the container.
One easy quick thing to do is to connect to the container on its first start, and do a `chown -R www-data:www-data /opt/b2evolution` (or with just the _cache and media folders) to ensure the permissions work for the container.

The Docker file does set the permissions on the folder in the container to attempt to have them set in the volumes, but this is not likely to matter when later connecting to a volume filled with files from another source.
The files and permissions need to be correct, or b2evolution will constantly warn of failures, and some features won't work because they can't write or access the files.

This example solves the problem of setting the permissions after running a container.
Run this after the regular docker run starts the (first) container:

```
docker exec b2evolution chown -R www-data:www-data /opt/b2evolution/_cache /opt/b2evolution/media

docker exec b2evolution chmod -R go+w /opt/b2evolution/_cache_ /opt/b2evolution/media
```

The first sets the owner on those volumes and the files within.
The second ensures the files are writable by the group and owner.

# Rebuilding the Container

These steps describe rebuilding the container. 

The basics are to checkout the contents from git, get b2evolution from its git, do a docker build, push the docker to a container repository, or run directly once the image is added to the local repository.

## Choices Made

As built, the container expects to use an external MySQL, and for the DB to already have been configured. 
This could clearly be added as part of a Docker Compose for ease.

To avoid warnings and security issues while running the blog, this build excludes the install directory, so there's no way to run the installer from this container. 
Install b2evolution separately and run through the b2evolution set-up, or remove the `.dockerignore` entry and rebuild the container.
This container expects the database to be configured for the same version of b2evolution as is pulled from git.

Apache was chosen over nginx as it's preferred by b2evolution.
It comes with configs and directives for Apache, so they are used rather than interpreted for the other platform.

All of the Apache configs needed for b2evolution are contained in the `sites-available/b2evolution.conf` file, that will be copied into the /etc/apache2 folder. 
It's a pretty straight-forward configuration with a listener on port 80 and an SSL listener on port 443.
The configuration also adds the default server name and directives for passing the variables from Docker to b2evolution.

Altering the `b2evolution.conf` file will allow changing those expectations. 
Reproducing the file to add other listeners or virtual domains should be done with care, as there are those few directives outside of the VirtualHost directives, and there need be only one Directory directive.

If using as built, but modifications are still desired, one could add a new file and add a Docker volume to replace /etc/apache2/sites-enabled with the new file.

This is also built expecting Let's Encrypt certificates, discussed below, managed external to the container. 
If SSL isn't desired, or Let's Encrypt folders aren't available to the containers, edit the `b2evolution.conf` file to remove the Directory for 443, or alter the SSL bits.

## Get b2evolution

The b2evolution software isn't included in the git repository with this Dockerfile and related configuration. 
Nor is a command to do the clone in the Dockerfile, as it would then require deleting the install folder after.
This way seems simple.

If rebuilding the container, start by by git cloning the b2evolution software with:

```
git clone https://github.com/b2evolution/b2evolution.git
```

Alternatively, refresh the git repository as necessary if it was previously cloned. 
There is a `gitclone.sh` script with this Dockerfile to make this easier for when rebuilding this container from scratch by checking out its git repository.

If any modifications are needed to the files, make them before performing the docker build.

## Understanding the Dockerfile

The Docker container is built with b2evolution installed in the /opt/b2evolution software, unaltered, except for these small things:

- The b2evolution/install folder isn't copied into the container for security.
This is excluded via the `.dockerignore` file. 
Remove (or alter) this from `.dockerignore` to allow a build to include the install folder.
- The `conf/_basic_config.php` file has environment variables instead of edited literals, and is copied into the b2evolution/conf folder. 
Ensure the variables are included when you run the container, or edit the file to include them directly.
- The sample.htaccess files in the b2evolution folder tree that are likewise copied to their relative .htaccess files.
These defaults are normally sufficient.
Each could be changed and replaced with an appropriate COPY command.
- The container /opt/b2evolution/_cache and /opt/b2evolution/media folders are made world-writable. 
These should be mounted to Docker volumes, as discussed above, for persistence between instances.

Optional contents in the `skins` or `plugins` folders can be added to allow adding things that aren't part of the default installation. 
This would require rebuilding the container, of course.
Optionally, make the folders and extend the container adding the COPY command again. 
Once started, configuration of the skin or plugin may also be necessary inside the software.

Rebuilding the container should only be necessary for confirming its contents, or keeping the installation folder.
Anything else should be achievable by extending the container.

# Extending the Container

Out-of-the-box installation may not work for everyone.
Checking out this build and rebuilding it with customizations works.
There's a better way, though.
A Docker way.

Instead of rebuilding this container, use it as a base and include modifications as necessary.
For example, if adding a plugin or skin, or increasing the number of sites hosted, create a new Docker file, referencing this container, and add customizations to it.

Start with a custom Docker file, adding the items as necessary.
Then perform a build and run:

```
docker build --tag custom-b2evolution
docker run -name b2evolution ...same-params... custom-b2evolution
```

Push to source control and Docker repositories as desired.
Easy and done!

Some examples follow.

## Example: Custom .htaccess

Adding items to an .htaccess file could be necessary.
Extending the container allows for adding a different COPY command to the extension, overwriting the sample.htaccess that are used to create the defaults.

This can be as simple as creating a small Dockerfile and adding the required bits for the changes desired.
This example copies a custom .htaccess to the root of the b2evolution folder:

```
FROM jekewa/b2evolution

COPY custom.htaccess /opt/b2evolution/.htaccess
```

## Example: Baking in Variables

The idea of the environment variables is to allow anyone to use the container without worrying about the configuration matching their environment.
Perpahs there are cases where maintaining a canned container with the variables always provided is preferred.
This can be helpful if the same bits are generally used, and could leave the sensitive bits (like the DB user and password) for the environment.

This can be as simple as creating a small Dockerfile with the desired variables.
For example, This will always use the server name, path, and assign the alias for the container:

```
FROM jekewa/b2evolution

ENV SERVER_NAME=not_my_real.com
ENV BASE_URL=http://not_my_real.com/blog/
ENV ALIAS=/blog/
```

The other required parameters will still need to be provided at the command line or in the container management system.
These can also be overridden with command line or containe managed values.

## Example: Adding Skins or Plugins

One of the strengths of b2evolution is its extensibility through skins and plugins.
This container contains only the skins and plugins in the base b2evolution source.
Adding other skins or plugins then requires either entering the container to install them, or baking them into a different version of the container.
The latter is recommended for repeatability.

Make the appropriate plugin or skin folder.
Copy the skin or plugin into a folder.
Make sure to expand any archives (i.e., a zip or tar file) and have the skin or plugin folder in the appropriate folder.

Make a simple Docker file such as this, including only the skins or plugins or both, as necessary:

```
FROM jekewa/b2evolution

COPY skins /opt/b2evolution/skins
COPY plugins /opt/b2evolution/plugins
```

On the first use of the container, the skin or plugin may need to "installed" and enabled through the b2evolution interface.
This configuration is saved in the database, so subsequent versions of the container with the same skins and plugins don't need to re-run the installation.

## Example: Additional Site

Making changes to allow for more than one site to be served from the same container (violates some Docker principles, but leverages some b2evolution capabilities) could be as easy as replacing the `b2evolution.conf` file, or adding additional files. 

Consider this example `other-site.conf` file:

```

<VirtualHost *:80>
  DocumentRoot /opt/b2evolution
  ServerName other.com

  DirectoryIndex index.php index.htm index.html
  AddHandler application/x-httpd-php .php

  php_value date.timezone "Pacific/Honolulu"

  Alias /another/path/ /opt/b2evolution/
</VirtualHost>
```

Add this simple Dockerfile:

```
FROM jekewa/b2evolution

COPY other-site.conf /etc/apache2/sites-available/

RUN a2ensite other-site
```

## Example: Always SSL

To leverage the included Let's Encrypt SSL, extend the container with this simple Dockerfile:

```
FROM jekewa/b2evolution

RUN a2ensite b2evolution-ssl
```

For ease, this Dockerfile-ssl is included in the source repository so simply building with the filename should make SSL with Let's Encrypt enabled by default.

```
docker build -f Dockerfile-ssl --tag b2evolution-ssl .
```
