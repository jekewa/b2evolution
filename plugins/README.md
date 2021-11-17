# Plugins

This is a placeholder folder to allow easy extension of the Docker container to include additional b2evolution plugins.

Create a folder with a plugins folder in it.
Download plugins from https://plugins.b2evolution.net/ or create some.
Add the expanded plugins folders to the plugins folder.

In the same folder, create a minimal Docker file, such as:

```
FROM jekewa/b2evolution

COPY plugins /opt/b2evolution/plugins
```

Build and deploy that container.

```
docker build --tag b2evolution .
docker run ... b2evolution
```
