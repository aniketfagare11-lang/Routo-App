<h1 align="center">🚀 Routo</h1>

<p align="center">
  <b>Smart Peer-to-Peer Delivery Platform</b><br/>
  <i>Move Smart. Deliver Faster.</i>
</p>

<p align="center">
  <a href="https://routo-app.web.app">
    <img src="https://img.shields.io/badge/🚀%20Live%20Demo-Click%20Here-orange?style=for-the-badge" />
  </a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Frontend-Flutter-blue?logo=flutter"/>
  <img src="https://img.shields.io/badge/Backend-Node.js%20%2B%20Express-green?logo=node.js"/>
  <img src="https://img.shields.io/badge/Database-Firebase-orange?logo=firebase"/>
  <img src="https://img.shields.io/badge/Maps-Google%20Maps%20API-red?logo=googlemaps"/>
  <img src="https://img.shields.io/badge/AI-Gemini-purple"/>
  <img src="https://img.shields.io/badge/Status-Hackathon%20MVP-success"/>
</p>

---

## 🌐 Live Demo

🚀 **Routo is Live Now!**

🔗 https://routo-app.web.app

> **Routo connects people sending parcels with travelers who are already heading in the same direction.**

---

## 🌍 Problem Statement

Traditional parcel delivery systems can suffer from:

* ❌ High delivery costs
* ❌ Longer delivery times
* ❌ Underutilized transportation capacity
* ❌ Inefficient use of existing travel routes

Meanwhile, thousands of people travel between cities every day with unused space in their vehicles.

**Routo turns those existing journeys into delivery opportunities.**

---

## 💡 Our Solution — Routo

Routo is a **peer-to-peer delivery platform** that connects:

* 📦 **Senders** who need to deliver parcels
* 🚗 **Travelers** who are already traveling toward the destination

Instead of creating a separate delivery trip, Routo utilizes an **existing journey** to move the parcel.

### The idea is simple:

> **Someone is already going there. Why not send your parcel with them?**

This creates value for both sides:

**Sender →** Faster and more convenient delivery

**Traveler →** Earn from available carrying capacity

---

## 🎯 Core Objectives

* ⚡ Enable faster peer-to-peer parcel delivery
* 💰 Create earning opportunities for travelers
* 📦 Utilize unused transportation capacity
* 🤝 Build a community-driven delivery network
* 🌱 Encourage efficient use of existing journeys

---

## ✨ Key Features

### 📦 Parcel Booking

Senders can create parcels by providing:

* Parcel title
* Description
* Pickup location
* Drop location
* Weight
* Reward amount

---

### 🚗 Traveler Route Creation

Travelers can publish their upcoming journeys:

* Starting city
* Destination city
* Vehicle type
* Available capacity
* Travel date

---

### 🔎 Smart Parcel Matching

Routo connects suitable parcels with travelers based on:

* Pickup and destination compatibility
* Available carrying capacity
* Parcel status
* Travel route

This helps utilize existing journeys instead of creating dedicated delivery trips.

---

### 📍 Delivery Tracking

Users can follow the parcel's delivery progress through the application.

The delivery lifecycle is represented through stages such as:

```text
PENDING
   ↓
ACCEPTED
   ↓
PICKED UP
   ↓
IN TRANSIT
   ↓
DELIVERED
```

---

### 🔐 Secure Delivery Verification

Routo uses OTP-based verification during the delivery process to provide an additional layer of trust between sender, traveler and recipient.

---

### 💰 Traveler Earnings

Travelers can earn rewards for carrying parcels along routes they are already traveling.

The platform records delivery-related earnings and transactions.

---

### 🤖 AI Assistance

Routo integrates **Gemini AI** to provide intelligent assistance within the application, helping users with guidance and platform-related queries.

---

### 🗺️ Route & Map Experience

Google Maps integration provides route and location visualization to make pickup, drop and travel information easier to understand.

---

## 🔄 Application Flow

### Sender

```text
Login
  ↓
Create Parcel
  ↓
Enter Pickup & Drop
  ↓
Set Weight & Reward
  ↓
Find Traveler
  ↓
Select Suitable Traveler
  ↓
Track Delivery
  ↓
Delivery Completed
```

### Traveler

```text
Login
  ↓
Create Travel Route
  ↓
Set Available Capacity
  ↓
View Matching Parcels
  ↓
Accept Parcel
  ↓
Pickup
  ↓
In Transit
  ↓
Complete Delivery
  ↓
Receive Reward
```

---

## 🏗️ System Architecture

```text
                 ┌──────────────────────┐
                 │      Routo User      │
                 │ Sender / Traveler    │
                 └──────────┬───────────┘
                            │
                            ▼
                 ┌──────────────────────┐
                 │    Flutter App       │
                 │      Frontend        │
                 └──────────┬───────────┘
                            │
                            ▼
                 ┌──────────────────────┐
                 │   Node.js + Express  │
                 │       Backend        │
                 └──────────┬───────────┘
                            │
                            ▼
                 ┌──────────────────────┐
                 │       Firebase       │
                 │      Database        │
                 └──────────┬───────────┘
                            │
              ┌─────────────┴─────────────┐
              ▼                           ▼
      ┌────────────────┐          ┌────────────────┐
      │ Google Maps API │          │   Gemini AI    │
      └────────────────┘          └────────────────┘
```

---

## 🛠️ Tech Stack

| Layer             | Technology                |
| ----------------- | ------------------------- |
| Frontend          | Flutter                   |
| Backend           | Node.js + Express         |
| Database          | Firebase                  |
| Maps & Location   | Google Maps API           |
| AI Assistance     | Gemini                    |
| API Communication | REST APIs                 |
| Development       | Dart + JavaScript/Node.js |
| Version Control   | Git + GitHub              |

---

## 🔐 Security & Reliability

Routo is designed with security and reliability in mind:

* 🔐 Authentication for users
* 🛡️ Backend-based API operations
* 🔑 Sensitive configuration kept outside publicly exposed source code
* 📦 Structured parcel and delivery management
* 🔒 OTP-based delivery verification
* ☁️ Firebase-backed data storage

> Sensitive credentials and private configuration values should be provided through environment/configuration files and should not be committed to the repository.

---

## 🧪 Testing & Reliability

The application has been tested across the primary delivery workflow, including:

```text
✓ User Registration
✓ User Login
✓ Parcel Creation
✓ Route Creation
✓ Parcel Matching
✓ Delivery Acceptance
✓ Pickup
✓ In Transit
✓ OTP Verification
✓ Delivery Completion
✓ Traveler Reward
```

The goal of testing was to verify the complete journey from **parcel creation to successful delivery**.

---

## 🌟 Unique Value Proposition

### For Senders

* ⚡ Convenient parcel delivery
* 📍 Route visibility
* 🔐 Verified delivery
* 🤝 Access to travelers already heading toward the destination

### For Travelers

* 💰 Earn from unused carrying capacity
* 🛣️ Monetize journeys they are already making
* 📦 Carry suitable parcels along their route

### For the Environment

* 🚗 Better utilization of existing journeys
* 🌱 Potential reduction in unnecessary dedicated delivery trips

---

## 📈 Future Scope

Routo can be expanded with:

* 🤖 Advanced intelligent matching
* 🗺️ Advanced route optimization
* 💳 Integrated payment gateway
* 🔔 Real-time push notifications
* ⭐ Traveler trust and rating system
* 📦 Multi-parcel optimization
* 🛡️ Enhanced KYC and identity verification
* 📊 Delivery analytics
* 🌐 Expansion to multiple cities
* 🚚 Larger community-based logistics network

---

## 📂 Project Structure

```text
Routo/
│
├── Frontend/
│   ├── lib/
│   ├── assets/
│   ├── android/
│   ├── ios/
│   ├── web/
│   └── pubspec.yaml
│
├── Backend/
│   ├── src/
│   ├── package.json
│   └── ...
│
└── README.md
```

---

## ⚙️ Local Setup

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/Project-Routo-Hackathon.git
cd Project-Routo-Hackathon
```

### 2. Backend Setup

```bash
cd Backend
npm install
```

Configure the required backend environment variables.

Then start the server:

```bash
npm start
```

### 3. Flutter Frontend Setup

From the frontend directory:

```bash
cd Frontend
flutter pub get
```

Run the application:

```bash
flutter run
```

For Flutter Web:

```bash
flutter run -d chrome
```

---

## 🎥 Demo

### 🚀 Live Application

https://routo-app.web.app

### 🎬 Demo Video

*Add your final demo video link here.*

---

## 🏆 Hackathon Project

Routo demonstrates a practical peer-to-peer logistics model:

```text
Existing Journey
       ↓
Suitable Parcel
       ↓
Traveler Match
       ↓
Verified Delivery
       ↓
Traveler Reward
```

The core concept is simple:

> **Use journeys that are already happening to move parcels more efficiently.**

---

## 👨‍💻 Team

<p align="center">
  <b>Team Routo</b>
</p>

---

## ❤️ Final Note

> **Routo is not just another delivery platform.**
>
> **It's a way to turn everyday journeys into delivery opportunities.**

<p align="center">
  ⭐ If you believe in smarter, community-powered logistics, consider starring this repository.
</p>
