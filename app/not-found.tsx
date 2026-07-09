import Link from "next/link";

export default function NotFound() {
  return (
    <div className="grid min-h-[50vh] place-items-center text-center">
      <div>
        <div className="text-6xl font-bold text-[color:var(--gold)]">404</div>
        <h2 className="mt-2 text-lg font-bold">الصفحة غير موجودة</h2>
        <p className="mt-1 text-sm text-[color:var(--text-muted)]">
          ربما حُذف هذا السجل أو تغيّر رابطه.
        </p>
        <Link
          href="/"
          className="mt-4 inline-block rounded-xl bg-[color:var(--primary)] px-5 py-2.5 text-sm font-semibold text-[color:var(--on-primary)] transition-opacity hover:opacity-90"
        >
          العودة إلى النظرة العامة
        </Link>
      </div>
    </div>
  );
}
