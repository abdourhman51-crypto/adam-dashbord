import { NextRequest, NextResponse } from "next/server";
import { ACCESS_COOKIE, REFRESH_COOKIE, refreshSession, verifyAccessToken } from "@/lib/supabase/session";

const PUBLIC_PATHS = ["/login"];

function isPublic(pathname: string) {
  return PUBLIC_PATHS.some((p) => pathname === p);
}

export async function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;

  const access = req.cookies.get(ACCESS_COOKIE)?.value;
  const refresh = req.cookies.get(REFRESH_COOKIE)?.value;

  let user = access ? await verifyAccessToken(access) : null;
  let refreshedCookies: { access: string; refresh: string; maxAge: number } | null = null;

  if (!user && refresh) {
    const session = await refreshSession(refresh);
    if (session) {
      user = session.user;
      refreshedCookies = {
        access: session.access_token,
        refresh: session.refresh_token,
        maxAge: session.expires_in ?? 3600,
      };
    }
  }

  if (isPublic(pathname)) {
    if (user) {
      const res = NextResponse.redirect(new URL("/", req.url));
      return res;
    }
    return NextResponse.next();
  }

  if (!user) {
    const loginUrl = new URL("/login", req.url);
    loginUrl.searchParams.set("next", pathname);
    const res = NextResponse.redirect(loginUrl);
    res.cookies.delete(ACCESS_COOKIE);
    res.cookies.delete(REFRESH_COOKIE);
    return res;
  }

  const res = NextResponse.next();
  if (refreshedCookies) {
    const secure = process.env.NODE_ENV === "production";
    res.cookies.set(ACCESS_COOKIE, refreshedCookies.access, {
      httpOnly: true,
      secure,
      sameSite: "lax",
      path: "/",
      maxAge: refreshedCookies.maxAge,
    });
    res.cookies.set(REFRESH_COOKIE, refreshedCookies.refresh, {
      httpOnly: true,
      secure,
      sameSite: "lax",
      path: "/",
      maxAge: 60 * 60 * 24 * 30,
    });
  }
  return res;
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|logo.png).*)"],
};
