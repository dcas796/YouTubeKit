# TODO

- Fix YTHTTPDownloader failing to download YouTube videos after less than 30s of operation. Throws a "Mismatched header range and response bytes"
- Make YTHTTPDownloader multi-threaded and improve download speed
- Implement ```downloadURL(for format: YTVideoFormat) async throws -> URL```
- Implement playlist support
- Support other YouTube video URL styles (```https://youtu.be/videoID```, ```https://www.youtube.com/embed/videoID```, etc.)
