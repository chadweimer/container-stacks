# calibre

## Initial Setup

Calibre Web requires an existing calibre library, which is mounted to `/books` inside the container in this stack.
The simplest way to create a library if you don't already have one is to run the desktop application to initialize a blank library, then copy it to location of the bind mount.

## Post Bring-up

### E-Book Conversion

Follow the instructions at <https://docs.linuxserver.io/images/docker-calibre-web/#application-setup> to set up the path to the `ebook-convert` binary.

### Homepage Widget

1. After logging in the first time, create a new user to use for the homepage widget, ideally with limited permissions
1. Update the environment variables to supply the `USERNAME` and `PASSWORD` for the user just created
1. Re-deply the stack
