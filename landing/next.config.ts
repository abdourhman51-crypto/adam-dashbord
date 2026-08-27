import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  async headers() {
    // Mobile browsers (Samsung Internet/Chrome on Android in particular)
    // aggressively cache this static-generated page, sometimes showing a
    // stale build well after a fresh production deploy. The document must
    // always be revalidated so every fix actually reaches the visitor.
    return [
      {
        source: "/:path*",
        headers: [{ key: "Cache-Control", value: "no-store, must-revalidate" }],
      },
    ];
  },
};

export default nextConfig;
