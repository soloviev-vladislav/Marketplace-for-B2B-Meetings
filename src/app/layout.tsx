import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "MeetMarket",
  description: "Marketplace for qualified B2B meetings",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="ru"><body className="min-h-screen font-sans antialiased">{children}</body></html>;
}
