import { NextResponse, type NextRequest } from "next/server";

// Optional password gate. Vercel login already protects *.vercel.app; set DASHBOARD_PASSWORD
// before pointing a public domain here. Browser prompt: user "adam", the password.
export function middleware(req: NextRequest) {
  const pass = process.env.DASHBOARD_PASSWORD;
  if (!pass) return NextResponse.next();
  const auth = req.headers.get("authorization") || "";
  const [scheme, b64] = auth.split(" ");
  if (scheme === "Basic" && b64) {
    const [, given] = atob(b64).split(":");
    if (given === pass) return NextResponse.next();
  }
  return new NextResponse("مطلوب كلمة السر", { status: 401, headers: { "WWW-Authenticate": 'Basic realm="Adam", charset="UTF-8"' } });
}

export const config = { matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"] };
