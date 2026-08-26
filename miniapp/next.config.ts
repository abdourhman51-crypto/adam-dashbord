import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  async headers() {
    // Telegram's in-app WebView (particularly on Android) is known to cache
    // the mini app's document aggressively across launches, sometimes
    // showing a stale build even after a fresh production deploy. Content
    // under /_next/static is already content-hashed and safe to cache
    // forever; the document itself must always be revalidated so a new
    // deploy is visible the next time a parent opens the app.
    return [
      {
        source: "/:path*",
        headers: [{ key: "Cache-Control", value: "no-store, must-revalidate" }],
      },
    ];
  },
};

export default nextConfig;
