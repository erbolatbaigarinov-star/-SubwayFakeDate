# SubwayFakeDate for LiveContainer

This project builds a small iOS tweak that makes only the injected app see:

**2022-07-09 12:00:00 UTC**

The iPhone itself keeps the real date, so normal HTTPS, Safari and other apps continue using the correct date.

Target bundle:
`com.kiloo.subwaysurfers`

## What the tweak changes

It hooks:
- `NSDate`
- `time()`
- `gettimeofday()`
- `clock_gettime(CLOCK_REALTIME)`

It intentionally does **not** fake monotonic clocks, because games use those for animation, frame timing and delays.

## Build with GitHub Actions

1. Create a new empty GitHub repository.
2. Upload **all files and folders from this project** to the repository root.
   The `.github/workflows/build.yml` path must remain exactly the same.
3. Commit the upload.
4. Open the repository's **Actions** tab.
5. Select **Build SubwayFakeDate**.
6. Press **Run workflow**.
7. Wait for the build to finish.
8. Open the completed run.
9. At the bottom under **Artifacts**, download:
   `SubwayFakeDate-LiveContainer`
10. Unzip it. You should get:
    - `SubwayFakeDate.dylib`
    - `SubwayFakeDate.plist`

## Install in LiveContainer

1. Open LiveContainer.
2. Open **Tweaks**.
3. Create a tweak folder, for example `Subway`.
4. Import `SubwayFakeDate.dylib`.
5. If LiveContainer supports importing the companion filter plist, also import `SubwayFakeDate.plist`.
6. Go to **Apps -> Subway Surf -> Tweak Folder**.
7. Select the `Subway` folder.
8. Fully close the guest app and LiveContainer, then reopen and launch Subway Surf.

Because the tweak folder is app-specific, other LiveContainer guest apps should not see the fake date.

## If the popup still appears

Then the version check is probably not using these standard wall-clock APIs. The next step would be to inspect the game binary / Unity IL2CPP code and hook the exact date/version check. Do not keep changing DNS domains at random.

## Change the fake date

Edit this line in `Tweak.xm`:

`static const time_t kFakeUnixTime = 1657368000;`

Then run the GitHub Action again.
