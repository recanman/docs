### Adjust audio by speed factor while keeping video in sync
`ffmpeg -i input.mkv -filter_complex "[0:v]setpts=<1/x>*PTS[v];[0:a]atempo=<x>[a]" -map "[v]" -map "[a]" output.mkv`
where `x` = `speed factor`, `<1/x>` = `1 / speed factor` (substitute it in)
