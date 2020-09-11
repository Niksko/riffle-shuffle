# riffle-shuffle

A tool to splice two videos together, a bit like a riffle shuffle

## Usage

### OSX

1. Ensure you have Docker Desktop installed. [Click here to download](https://download.docker.com/mac/stable/Docker.dmg). Open the downloaded file and it should prompt you to install 
Docker desktop.
2. Download this repository. [Click here to download](https://github.com/Niksko/riffle-shuffle/archive/master.zip)
3. Figure out where the zip file downloaded to and go there in Finder. It's probably in your Downloads folder.
4. Unzip the files by double clicking on the file `riffle-shuffle-master.zip`
5. Go inside the folder that will be created `riffle-shuffle-master`
6. There should be a folder called `input`. Inside this folder, put the videos you want to riffle together. You must call them `first.mp4` and `second.mp4`.
7. Go back to the `riffle-shuffle-master` folder.
8. Find the file called `riffle`. Right click on it, select 'Open with', and down the bottom select 'Other...'.
At the bottom of the panel, click the dropdown that says 'Recommended Applications' and select 'All Applications'.
In the list, there should be a folder called 'Utilities'. From there, select 'Terminal' and click 'Open'.
9. A small window should pop up, and you should see `RIFFLE` in block letters. It may take a while. Once you see `DONE` in block letters, it's finished.
10. The result file will be called `result` inside of the folder called output, nearby the `input` folder you put the files into above.

## Development notes

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
docker run --rm -it -v $(pwd):/workdir linuxserver/ffmpeg -i /workdir/<input-file>.mp4 /workdir/frame%05d.png
```

### Stitching a video back together

### Algorithm for calculating each chunk

First, some terminology. Let's call each contiguous set of frames from a single source video a 'chunk'. The goal is to
take two source videos (`src-A` and `src-B`), split each video into 'chunks' of decreasing size, and then reassemble the chunks
so that you get a chunk from `src-A`, then `src-B`, then `src-A`, etc. until you've seen all of both videos.

If we had two videos of 10 frames each, we could split up our chunks so that each chunk was one frame shorter than the last.
If we denote a chunk from `src-X` of length `n` frames as `nX` (e.g. a chunk from `src-A` of length `5` frames would be `5A`),
then for the 10 frame sources we would get a result that looks like:

```
4A 4B 3A 3B 2A 2B 1A 1B
```

`4 + 3 + 2 + 1 = 10`, so the math works out. This hints at how to calculate the length of the first 'chunk'.

Using the formula that `1 + 2 + 3 + 4 + 5 + ... + n = n(n+1)/2`, we can work backwards to compute the value we want, i.e. `n`.

```
total number of frames = n(n+1)/2
n^2 + n + 2 * total number of frames = 0
```

This is quadratic, so by the quadratic formula:

```
n = ( sqrt(1 + 8 * frames) - 1 ) / 2
```

This is only going to be a whole number for some special numbers of frames (triangular numbers?), so we take the `floor`
of this as our starting 'chunk' size. Since we'll usually have some frames left over (because we took the floor), we add
the extra frames to the first chunk.
