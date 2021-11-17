# Skins

This is a placeholder folder to allow easy extension of the Docker container to include additional b2evolution skins.

Create a folder with a skins folder in it.
Download skins from https://skins.b2evolution.net/ or create some.
Add the expanded skin folders to the skins folder.

In the same folder, create a minimal Docker file, such as:

```
FROM jekewa/b2evolution

COPY skins /opt/b2evolution/skins
```

Build and deploy that container.

```
docker build --tag b2evolution .
docker run ... b2evolution
```
