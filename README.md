# MovieZone Flutter App

This project keeps the existing MovieZone-style UI structure while using the MovieZone backend as the app data source.

## Backend
Default backend:
`https://moviezone-backend-1r89.onrender.com`

Override at build time if needed:
`flutter build apk --release --dart-define=MOVIEZONE_BACKEND_URL=https://your-backend-url`

## Main MovieZone API flow
- Bootstrap: `/api/bootstrap`
- Home: `/api/v2/home`
- Search: `/api/search/v2`
- Media details: `/api/media/:id`
- Related: `/api/media/:id/related`
- Playback: `/api/stream/:id?season=:season&episode=:episode`

Playback requests go through the MovieZone backend. The app does not use the old MovieZone cookie/add verification flow.
