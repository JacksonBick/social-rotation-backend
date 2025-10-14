# 🔐 OAuth Setup Guide

This guide will help you set up OAuth authentication for Facebook, LinkedIn, and Google My Business.

## Prerequisites

You'll need to create developer apps on each platform to get OAuth credentials.

---

## 📘 Facebook OAuth Setup

### Step 1: Create Facebook App
1. Go to https://developers.facebook.com/apps
2. Click **"Create App"**
3. Select **"Business"** as app type
4. Fill in app details:
   - App Name: "Social Rotation"
   - Contact Email: your email
5. Click **"Create App"**

### Step 2: Configure OAuth Settings
1. In your app dashboard, go to **Settings** → **Basic**
2. Copy your **App ID** and **App Secret**
3. Add **App Domains**: `localhost` (for development)
4. Click **"Add Platform"** → **"Website"**
5. Site URL: `http://localhost:3000`

### Step 3: Add Facebook Login
1. Go to **Products** → **Add Product**
2. Find **"Facebook Login"** and click **"Set Up"**
3. Choose **"Web"**
4. In **Facebook Login** → **Settings**:
   - Valid OAuth Redirect URIs: `http://localhost:3000/api/v1/oauth/facebook/callback`
5. Click **"Save Changes"**

### Step 4: Request Permissions
1. Go to **App Review** → **Permissions and Features**
2. Request these permissions:
   - `pages_manage_posts`
   - `pages_read_engagement`
   - `instagram_basic`
   - `instagram_content_publish`
   - `publish_video`

### Step 5: Add to .env
```bash
FACEBOOK_APP_ID=your_app_id_here
FACEBOOK_APP_SECRET=your_app_secret_here
```

---

## 💼 LinkedIn OAuth Setup

### Step 1: Create LinkedIn App
1. Go to https://www.linkedin.com/developers/apps
2. Click **"Create app"**
3. Fill in details:
   - App name: "Social Rotation"
   - LinkedIn Page: Select your company page (or create one)
   - Privacy policy URL: Your privacy policy
   - App logo: Upload a logo
4. Click **"Create app"**

### Step 2: Configure OAuth
1. Go to **Auth** tab
2. Copy **Client ID** and **Client Secret**
3. Add **Redirect URLs**:
   - `http://localhost:3000/api/v1/oauth/linkedin/callback`
4. Click **"Update"**

### Step 3: Request Permissions
1. Go to **Products** tab
2. Request **"Share on LinkedIn"** product
3. Request **"Sign In with LinkedIn"** product

### Step 4: Add to .env
```bash
LINKEDIN_CLIENT_ID=your_client_id_here
LINKEDIN_CLIENT_SECRET=your_client_secret_here
```

---

## 🗺️ Google My Business OAuth Setup

### Step 1: Create Google Cloud Project
1. Go to https://console.cloud.google.com
2. Click **"Select a project"** → **"New Project"**
3. Project name: "Social Rotation"
4. Click **"Create"**

### Step 2: Enable APIs
1. Go to **APIs & Services** → **Library**
2. Search and enable:
   - **Google My Business API**
   - **Google Business Profile API**

### Step 3: Create OAuth Credentials
1. Go to **APIs & Services** → **Credentials**
2. Click **"Create Credentials"** → **"OAuth client ID"**
3. Configure consent screen first if prompted:
   - User Type: **External**
   - App name: "Social Rotation"
   - User support email: your email
   - Developer contact: your email
4. Application type: **Web application**
5. Name: "Social Rotation Web Client"
6. Authorized redirect URIs:
   - `http://localhost:3000/api/v1/oauth/google/callback`
7. Click **"Create"**
8. Copy **Client ID** and **Client Secret**

### Step 4: Add to .env
```bash
GOOGLE_CLIENT_ID=your_client_id_here
GOOGLE_CLIENT_SECRET=your_client_secret_here
```

---

## 🐦 Twitter OAuth Setup (Coming Soon)

Twitter uses OAuth 1.0a which is more complex. This will be implemented in a future update.

---

## 🔧 Complete .env File

Create a `.env` file in your Rails backend root directory:

```bash
# Frontend URL
FRONTEND_URL=http://localhost:3001

# Database
DATABASE_URL=postgresql://username:password@localhost/rebrand_social_rotation_development

# Facebook OAuth
FACEBOOK_APP_ID=your_facebook_app_id
FACEBOOK_APP_SECRET=your_facebook_app_secret

# LinkedIn OAuth
LINKEDIN_CLIENT_ID=your_linkedin_client_id
LINKEDIN_CLIENT_SECRET=your_linkedin_client_secret

# Google OAuth
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret

# Twitter OAuth (OAuth 1.0a)
TWITTER_API_KEY=your_twitter_api_key
TWITTER_API_SECRET=your_twitter_api_secret

# Digital Ocean Spaces
DO_SPACES_KEY=your_do_spaces_key
DO_SPACES_SECRET=your_do_spaces_secret
DO_SPACES_ENDPOINT=https://nyc3.digitaloceanspaces.com
DO_SPACES_REGION=nyc3
DO_SPACES_BUCKET=your_bucket_name
```

---

## 🧪 Testing OAuth

1. Start your Rails server: `rails server`
2. Start your React app: `npm run dev`
3. Go to http://localhost:3001/profile
4. Click **"Connect Facebook"** (or LinkedIn/Google)
5. A popup will open with the OAuth flow
6. Authorize the app
7. You'll be redirected back with a success message
8. The connection status will update to "Connected"

---

## 🚨 Important Notes

- **Development Mode**: OAuth apps need to be in "Development Mode" initially
- **HTTPS**: Production OAuth requires HTTPS
- **Callback URLs**: Must match exactly (including protocol and port)
- **Permissions**: Some permissions require app review by the platform
- **Rate Limits**: Each platform has API rate limits

---

## 🔒 Security

- OAuth state tokens prevent CSRF attacks
- Access tokens are stored securely in the database
- Never commit `.env` files to git
- Use environment variables for all secrets

---

## 📚 Resources

- [Facebook OAuth Docs](https://developers.facebook.com/docs/facebook-login/web)
- [LinkedIn OAuth Docs](https://learn.microsoft.com/en-us/linkedin/shared/authentication/authentication)
- [Google OAuth Docs](https://developers.google.com/identity/protocols/oauth2)

