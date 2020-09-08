#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat << EOF
Usage: $(basename "${0}") <first-input-filename> <second-input-filemame> <output-filename>

Riffles two video files together

EOF
  exit 1
}

(($# != 3)) && usage

first_filename="${1}"
second_filename="${2}"
output_filename="${3}"

output_dir="output"
output_filepath="${output_dir}/${output_filename}"
first_frame_dir="${output_dir}/first-frames"
second_frame_dir="${output_dir}/second-frames"
result_dir="${output_dir}/result-frames"

mkdir -p "${output_dir}"
mkdir -p "${first_frame_dir}"
mkdir -p "${second_frame_dir}"
mkdir -p "${result_dir}"

docker run --rm -it -v $(pwd):/workdir linuxserver/ffmpeg -i /workdir/"${first_filename}" "/workdir/${first_frame_dir}/frame%05d.jpg"
docker run --rm -it -v $(pwd):/workdir linuxserver/ffmpeg -i /workdir/"${second_filename}" "/workdir/${second_frame_dir}/frame%05d.jpg"

number_of_frames=$(ls "${first_frame_dir}" | wc -l)

echo "Found ${number_of_frames} frames"

# Figure out where to start our frame count
# 1 + 2 + 3 + 4 + ... + n = n * (n + 1) / 2
# n^2 + n - (2*frames)
# n = sqrt(1 + 8 * frames) - 1 / 2
# Generally this isn't going to be a round number. Hence, we need to take
# floor(n) as our starting number of frames
# We're going to have more frames in the first chunks, so figure out frames - floor(n) * (floor(n) + 1) / 2 for the first chunk

n=$(bc <<< "(sqrt(1+8*${number_of_frames})-1)/2")
first_chunk=$(bc <<< "${number_of_frames}-(${n}*(${n}+1)/2)+${n}")

echo "Computed n = ${n} (largest frame length). First chunk is ${first_chunk} (first chunk has leftover frames)"

result_frame=1
first_video_frame=1
second_video_frame=1
chunk_size="${first_chunk}"
while [ "${chunk_size}" -gt "0" ]
do
  j=0
  while [ "${j}" -lt "${chunk_size}" ]
  do
    cp $(printf "${first_frame_dir}/frame%05d.jpg" "${first_video_frame}") $(printf "${result_dir}/frame%05d.jpg" "${result_frame}")
    j=$((${j}+1))
    result_frame=$((${result_frame}+1))
    first_video_frame=$((${first_video_frame}+1))
  done

  j=0
  while [ "${j}" -lt "${chunk_size}" ]
  do
    cp $(printf "${second_frame_dir}/frame%05d.jpg" "${second_video_frame}") $(printf "${result_dir}/frame%05d.jpg" "${result_frame}")
    j=$((${j}+1))
    result_frame=$((${result_frame}+1))
    second_video_frame=$((${second_video_frame}+1))
  done

  if [ "${chunk_size}" -eq "${first_chunk}" ]; then
    chunk_size="${n}"
  fi
  chunk_size=$((${chunk_size}-1))
done

docker run --rm -it -v $(pwd):/workdir linuxserver/ffmpeg -r 24 -f image2 -i "/workdir/${result_dir}/frame%05d.jpg" -vcodec libx264 -crf 25 "/workdir/${output_filepath}"