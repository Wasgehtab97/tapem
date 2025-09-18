/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: { unoptimized: true },
  experimental: { typedRoutes: true },
  eslint: { ignoreDuringBuilds: true },
  productionBrowserSourceMaps: false
};
module.exports = nextConfig;
