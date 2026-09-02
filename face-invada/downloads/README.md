Sideload binaries are built locally with `../native/build-android.sh`.

They are **not** committed or published on GitHub. After a local build you get:

- `FaceInvadaBeatBoxing.apk`
- `FaceInvadaBeatBoxing-web.zip`

Serve this folder with `python3 -m http.server` and open `../downloads.html`.
