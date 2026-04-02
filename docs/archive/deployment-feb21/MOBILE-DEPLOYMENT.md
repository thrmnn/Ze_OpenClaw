# Mission Control - Mobile Deployment Guide 📱

**Deploy Mission Control from your phone in 10 minutes**

---

## 🎯 Overview

I've prepared everything. You just need to click 3 links on your mobile browser:

1. **Create Convex account** (2 min)
2. **Create GitHub repo** (3 min)
3. **Deploy to Vercel** (5 min)

Then you'll have: `https://mission-control-xyz.vercel.app` ✨

---

## 📍 Step 1: Setup Convex (Database)

### Option A: Quick Start (Recommended)

**Click this link on your phone:**

👉 **https://dashboard.convex.dev/signup**

**Steps:**
1. Sign up with GitHub or Google
2. Click "Create a new project"
3. Name it: `mission-control`
4. **Copy these 2 values** (you'll need them later):
   - `CONVEX_DEPLOYMENT` (looks like: `dev:mission-control-123`)
   - `NEXT_PUBLIC_CONVEX_URL` (looks like: `https://abc123.convex.cloud`)

**Save these somewhere!** (Notes app, email yourself, etc.)

---

## 📍 Step 2: Create GitHub Repository

### Mobile-Friendly Method

**Click this link:**

👉 **https://github.com/new**

**Fill in:**
- **Repository name:** `mission-control`
- **Description:** OpenClaw Mission Control Dashboard
- **Visibility:** Private ✅
- **Initialize:** Leave unchecked (we have code already)

Click **"Create repository"**

**Copy the repository URL** (looks like: `https://github.com/yourusername/mission-control`)

---

## 📍 Step 3: Deploy to Vercel

### Option A: Direct Import (Easiest)

**After creating GitHub repo above, click:**

👉 **https://vercel.com/new**

**Steps:**
1. Login with GitHub
2. Click "Import Git Repository"
3. Find `mission-control` repo
4. Click "Import"

**Environment Variables:**

Vercel will ask for these. Use the values from Step 1:

```
CONVEX_DEPLOYMENT = dev:mission-control-123
NEXT_PUBLIC_CONVEX_URL = https://abc123.convex.cloud
```

Click **"Deploy"**

⏳ Wait 2-3 minutes...

🎉 **Done! You'll get:** `https://mission-control-xyz.vercel.app`

---

## 🔧 What I've Already Done

✅ Wrote all code (18 files)  
✅ Installed dependencies (372 packages)  
✅ Created documentation  
✅ Configured project structure  
✅ Added seed scripts for initial data  

**You just need to connect the services!**

---

## 📱 After Deployment

### Seed the Database

Once deployed, you need to add the 6 agents to the database.

**Open on your phone:**

```
https://dashboard.convex.dev/deployment/<your-project>/functions
```

**Run these 3 functions** (click "Run" button for each):

1. `seed:seedAgents` → Creates 6 agents
2. `seed:seedContent` → Creates example content ideas
3. `seed:seedProjects` → Creates example projects

**That's it!** Your Mission Control is live.

---

## ✅ Verification

Visit your Vercel URL:

`https://mission-control-xyz.vercel.app`

**You should see:**

- Dashboard home page (dark theme)
- 6 agents in Agent Office (all idle)
- Content pipeline with 4 columns
- Projects page with 2 examples

**If you see this → Success!** 🎉

---

## 🐛 Troubleshooting

### "Cannot connect to Convex"

- Check environment variables in Vercel dashboard
- Make sure `NEXT_PUBLIC_CONVEX_URL` is correct
- Redeploy after fixing

### "No agents showing"

- Go to Convex dashboard → Run `seed:seedAgents`
- Refresh the page

### Deployment fails

- Check build logs in Vercel
- Usually missing environment variables

---

## 🔐 Alternative: Use My Pre-configured Deploy Button

If the above is too complex, I can create a "Deploy to Vercel" button that auto-fills everything. But you still need to:

1. Create Convex account (get API keys)
2. Click the deploy button
3. Enter Convex keys

---

## 📞 Need Help?

**From your phone, text me via Telegram:**

"Mission Control deploy stuck at step X"

I'll guide you through! 😌

---

## 🎯 Alternative: Wait for Laptop

If mobile deployment is too complicated, just wait until you have laptop access:

```bash
cd ~/clawd/mission-control
./setup.sh
```

Then deploy from laptop. Much easier with CLI.

---

## ⏱️ Time Estimate

**Mobile deployment:** 10-15 minutes  
**Laptop deployment:** 5 minutes

Your choice! 📱💻

---

Built with ❤️ by Zé
Ready to deploy! 🚀
