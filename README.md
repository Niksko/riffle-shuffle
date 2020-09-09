# riffle-shuffle

A tool to splice two videos together, a bit like a riffle shuffle

## Usage

### OSX

1. Ensure you have Docker Desktop installed. [Click here to download](https://download.docker.com/mac/stable/Docker.dmg). Open the downloaded file and it should prompt you to install 
Docker desktop.
2. Open the terminal. Use Command+Spacebar and type 'Terminal', then hit enter
3. Download this repository. [Click here to download](https://github.com/Niksko/riffle-shuffle/archive/master.zip)
4. Figure out where the zip file downloaded to and go there in Finder.
5. Unzip the files by double clicking on them in Finder.
6. Go inside the folder of unzipped files
7. Navigate inside the unzipped folder in the Terminal. The easiest way to do this is to type `cd` in the terminal,
then drag a file from inside the unzipped folder from Finder onto the terminal window. This will put the path of the file
in your terminal, and now you can delete everything after the final slash and hit enter to go there.
For example, once you've dragged the file, you'll see something like `cd /Users/nskoufis/Downloads/a-folder-we-want-to-go-to/something.md`.
Delete the `something.md` so that it says `cd /Users/nskoufis/Downloads/a-folder-we-want-to-go-to/` and then hit enter.
8. Put the files you want to splice together inside the folder in Finder. Try and name them something without spaces in the name.
Currently, the first video should be shorter than the second video.
9. Cross your fingers.
10. In the terminal, type `./riffle.sh <name-of-first-video> <name-of-second-video> result.mp4`, but replace `<name-of-first-video>` and `<name-of-second-video>`
with the actual names of the videos you want to use, including their file extensions e.g. `.avi`, `.mp4`, so `my-video.avi` or `my-other-cool-video.mp4`.
11. Press enter in the terminal. If you see something that says `Starting to Riffle` it might just be working.
12. You should see DONE in block letter's when it's finished. It may take a while.
13. The resulting video will be in a sub-folder called `output`. The file will be called `result.mp4`

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
