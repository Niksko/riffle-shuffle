# riffle-shuffle

A tool to splice two videos together, a bit like a riffle shuffle

## Usage

### Setup

Grabbed the Blender foundations `big-buck-bunny.mp4` from [a gist](https://gist.github.com/jsturgis/3b19447b304616f18657)
of test videos.

### Preparing videos for use

We can use the `linuxserver/ffmpeg` container to split videos.

Usage:

```
docker run --rm -it -v $(pwd):/workdir linuxserver/ffmpeg -i /workdir/<input-file>.mp4 -ss <start-seconds> -t <end-seconds> /workdir/<output-filename>.mp4
```

Split big buck bunny into the first five mins, and five mins from 60 seconds in

### Splitting a video into frames

```
docker run --rm -it -v $(pwd):/workdir linuxserver/ffmpeg -i /workdir/<input-file>.mp4 /workdir/frame%04d.jpg
```