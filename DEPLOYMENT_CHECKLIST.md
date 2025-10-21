# OAuth Deployment Checklist

## 1. Environment Variables (CRITICAL)
Add these to your production environment (Digital Ocean App Platform):

```
# OAuth Credentials
LINKEDIN_CLIENT_ID=86e3q5wfvamuqa
LINKEDIN_CLIENT_SECRET=BP8wbuFAJGCVIYDq

GOOGLE_CLIENT_ID=1050295806479-d29blhmka53vtmj3dgshp59arp8ic8al.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=wyZs7M4qFFvd1C1TVQGqvY27

# Digital Ocean Spaces
DIGITAL_OCEAN_SPACES_KEY=SAGDZELGX2GCZDRXZWWU
DIGITAL_OCEAN_SPACES_SECRET=nYlc9IKq7eEp4vKYXPwTy4GKlL8rRxEsI47b63HX3M4
DIGITAL_OCEAN_SPACES_NAME=se1
DIGITAL_OCEAN_SPACES_REGION=sfo2
DIGITAL_OCEAN_SPACES_ENDPOINT=https://sfo2.digitaloceanspaces.com
```

## 2. OAuth App Settings (CRITICAL)
Update your OAuth app redirect URIs:

### LinkedIn App (Client ID: 86e3q5wfvamuqa)
- Go to: https://www.linkedin.com/developers/apps
- Add redirect URI: `https://my.socialrotation.app/linkedin/callback`

### Google App (Client ID: 1050295806479-...)
- Go to: https://console.cloud.google.com/apis/credentials
- Add redirect URI: `https://my.socialrotation.app/google/callback`

## 3. Dependencies
The following gems were added and need to be installed in production:
- `dotenv-rails` (for environment variables)
- `httparty` (for OAuth API calls)

## 4. Database Migrations
All migrations are already applied. No new migrations needed.

## 5. Routes
OAuth routes are already configured:
- `/api/v1/oauth/linkedin/login`
- `/api/v1/oauth/linkedin/callback`
- `/api/v1/oauth/google/login`
- `/api/v1/oauth/google/callback`

## 6. What Will Work After Deployment:
✅ Users can click "Connect LinkedIn" in Profile page
✅ LinkedIn OAuth popup will open
✅ Users authenticate with LinkedIn
✅ LinkedIn redirects to: `https://my.socialrotation.app/linkedin/callback`
✅ Backend exchanges code for access token
✅ Access token is saved to user record
✅ User is redirected to: `https://my.socialrotation.app/profile?success=linkedin_connected`
✅ Same flow works for Google OAuth

## 7. Testing After Deployment:
1. Log into your app
2. Go to Profile page
3. Click "Connect LinkedIn"
4. Sign in to LinkedIn
5. Should redirect back with success message
6. LinkedIn should show as "Connected" in Profile

## 8. Troubleshooting:
- If redirect URI error: Double-check OAuth app settings
- If session error: Verify sessions are enabled in production
- If access token error: Check environment variables are set

