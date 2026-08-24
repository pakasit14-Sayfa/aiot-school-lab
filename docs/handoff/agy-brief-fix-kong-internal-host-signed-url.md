# Brief for agy: signed download URLs return the Docker-internal `kong:8000` host — student can't actually open files

Verified end-to-end today with real login, real upload, real download call
(not `flutter analyze`/`flutter test`). Upload works completely. Download
is broken for any real client — confirmed reproducible, not an artifact of
how I tested it.

## The bug

`lesson-material-download/index.ts` and `course-file-download/index.ts`
both build their Supabase client like this:

```ts
const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  serviceRoleKey,
);
```

Locally, the Supabase CLI sets `SUPABASE_URL` **inside the edge-function
container** to `http://kong:8000` — the Docker-internal hostname for the
gateway. That's correct for the edge function's own outbound calls (RPC,
storage), which happen *inside* the Docker network. But
`supabase.storage.from(bucket).createSignedUrl(...)` bakes that same host
into the URL string it returns, and both functions pass it straight
through to the client as `signed_url`:

```ts
return json({
  signed_url: signed.data.signedUrl,   // literally "http://kong:8000/storage/v1/object/sign/..."
  file_name: lookup.data.file_name,
});
```

`student_lesson_view_page.dart` (`_openMaterial`, line ~154) takes that
string as-is and calls `launchUrl(Uri.parse(url))`. No rewriting anywhere
in between.

**Confirmed live**: uploaded a real file as teacher, called
`lesson-material-download` as an enrolled student, got back
`http://kong:8000/storage/v1/object/sign/lesson-materials/...`. `curl`
to that URL exactly as returned → connection failure (`kong` doesn't
resolve outside the Docker network — a Flutter app on the host or a
student's actual device can't reach it either). Rewriting only the host
to `127.0.0.1:54321` (same path, same token, untouched) → `200`, bytes
matched the uploaded file exactly. So the signing/access-control logic is
correct — only the returned host is wrong.

This hits **both** download functions (same copied pattern per hard rule
3 in CLAUDE.md): `lesson-material-download` and `course-file-download`.
Upload is unaffected — `uploadBinaryToSignedUrl()` is a client-side call
that uses the Flutter app's own configured `SUPABASE_URL`
(`http://127.0.0.1:54321`, from `env.json`), not anything server-returned.

## Fix

Don't change what the client (inside the function) uses to reach
Storage/RPC internally — that has to stay the Docker-internal
`SUPABASE_URL` for the function to work at all. Instead, rewrite just the
**returned** URL's origin to a public-facing base URL before sending it
back to the app. Add a separate env var, e.g. `PUBLIC_STORAGE_URL`, read
in both `lesson-material-download` and `course-file-download`:

```ts
const publicBaseUrl = Deno.env.get("PUBLIC_STORAGE_URL") ?? Deno.env.get("SUPABASE_URL")!;
// ... after createSignedUrl:
const signedUrl = new URL(signed.data.signedUrl);
const publicUrl = new URL(publicBaseUrl);
signedUrl.protocol = publicUrl.protocol;
signedUrl.host = publicUrl.host;

return json({
  signed_url: signedUrl.toString(),
  file_name: lookup.data.file_name,
});
```

Set `PUBLIC_STORAGE_URL=http://127.0.0.1:54321` in `supabase/.env` (or
wherever local function env vars are already set — check how
`SUPABASE_SERVICE_ROLE_KEY` gets into the function's env today and put
this next to it) for local dev. That's the exact value the app itself
already uses (`env.json` → `SUPABASE_URL`), so it's the correct target,
not a guess.

For whatever gets deployed to a real/hosted project later, this same var
should be set to that project's public API URL — flag that in the
migration/deploy notes if there's a deploy step, but don't block this fix
on it; local dev is what's broken right now and what I could verify.

## Verify

Don't trust `flutter analyze`/`flutter test` for this — same lesson as
everything else today. Repeat exactly what I did:

1. Login as teacher, upload a real file to a real lesson (or course file),
   confirm `200` from the signed-upload PUT.
2. Login as the enrolled student, call `lesson-material-download` (and
   separately `course-file-download` if that one's in scope too), take
   the `signed_url` **exactly as returned** — don't rewrite it yourself —
   and `curl` it directly.
3. Must return `200` with the file's real bytes, using the URL exactly as
   the function sent it. If you have to manually swap the host to get a
   `200`, the fix isn't done — that's the whole bug.
4. Also re-run the access-control probes (bad token, bad material/file id,
   wrong role) to make sure the rewrite didn't loosen anything — should
   still be `403` on all three.
