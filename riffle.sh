#!/usr/bin/env bash
set -euo pipefail

cat << EOF
Starting to...
██████  ███ ███████ ███████ █       ███████
█     █  █  █       █       █       █
█     █  █  █       █       █       █
██████   █  █████   █████   █       █████
█   █    █  █       █       █       █
█    █   █  █       █       █       █
█     █ ███ █       █       ███████ ███████
EOF

basepath="$(dirname $(realpath ${0}))"

first_filename="input/first.mp4"
second_filename="input/second.mp4"
output_filename="result.mp4"

output_dir="output"
output_filepath="${output_dir}/${output_filename}"
first_frame_dir="${output_dir}/first-frames"
second_frame_dir="${output_dir}/second-frames"
result_dir="${output_dir}/result-frames"

mkdir -p "${basepath}/${output_dir}"
mkdir -p "${basepath}/${first_frame_dir}"
mkdir -p "${basepath}/${second_frame_dir}"
mkdir -p "${basepath}/${result_dir}"

docker run --rm -it -v "${basepath}":/workdir linuxserver/ffmpeg -i /workdir/"${first_filename}" "/workdir/${first_frame_dir}/frame%05d.png"
docker run --rm -it -v "${basepath}":/workdir linuxserver/ffmpeg -i /workdir/"${second_filename}" "/workdir/${second_frame_dir}/frame%05d.png"

number_of_frames=$(ls "${basepath}/${first_frame_dir}" | wc -l)

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
    cp $(printf "${basepath}/${first_frame_dir}/frame%05d.png" "${first_video_frame}") $(printf "${basepath}/${result_dir}/frame%05d.png" "${result_frame}")
    j=$((${j}+1))
    result_frame=$((${result_frame}+1))
    first_video_frame=$((${first_video_frame}+1))
  done

  j=0
  while [ "${j}" -lt "${chunk_size}" ]
  do
    cp $(printf "${basepath}/${second_frame_dir}/frame%05d.png" "${second_video_frame}") $(printf "${basepath}/${result_dir}/frame%05d.png" "${result_frame}")
    j=$((${j}+1))
    result_frame=$((${result_frame}+1))
    second_video_frame=$((${second_video_frame}+1))
  done

  if [ "${chunk_size}" -eq "${first_chunk}" ]; then
    chunk_size=$((${n}-1))
  fi
  chunk_size=$((${chunk_size}-1))
done

docker run --rm -it -v "${basepath}":/workdir linuxserver/ffmpeg -r 24 -f image2 -i "/workdir/${result_dir}/frame%05d.png" -vcodec libx264 -crf 25 "/workdir/${output_filepath}"

cat << EOF
██████  ███████ █     █ ███████
█     █ █     █ ██    █ █
█     █ █     █ █ █   █ █
█     █ █     █ █  █  █ █████
█     █ █     █ █   █ █ █
█     █ █     █ █    ██ █
██████  ███████ █     █ ███████
EOF