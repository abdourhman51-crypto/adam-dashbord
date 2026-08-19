import { LayoutDashboard, TrendingUp, Users, ShieldCheck, BarChart3 } from "lucide-react";

export const NAV_ITEMS = [
  { href: "/", label: "نظرة عامة", icon: LayoutDashboard },
  { href: "/stages", label: "صحة الرحلات", icon: TrendingUp },
  { href: "/customers", label: "العملاء", icon: Users },
  { href: "/patterns", label: "مراجعة الأنماط", icon: ShieldCheck },
  { href: "/insights", label: "فهم العميل", icon: BarChart3 },
] as const;
