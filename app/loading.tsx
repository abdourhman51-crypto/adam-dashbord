export default function Loading() {
  return (
    <div className="space-y-6" role="status" aria-label="جارٍ تحميل البيانات">
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 xl:grid-cols-6">
        {Array.from({ length: 6 }).map((_, i) => (
          <div key={i} className="skeleton h-20" />
        ))}
      </div>
      <div className="grid gap-4 lg:grid-cols-3">
        <div className="skeleton h-80 lg:col-span-2" />
        <div className="skeleton h-80" />
      </div>
      <div className="grid gap-4 lg:grid-cols-2">
        <div className="skeleton h-64" />
        <div className="skeleton h-64" />
      </div>
      <span className="sr-only">جارٍ تحميل البيانات…</span>
    </div>
  );
}
