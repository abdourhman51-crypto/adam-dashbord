import Image from "next/image";

const SIZES = { sm: 36, md: 56, lg: 88 } as const;

/** شعار الشجرة نفسه هو أيقونة التحميل — حلقة ذهبية دوّارة + نبض هادئ، بدل دائرة مسطّحة. */
export function TreeLoader({ size = "md" }: { size?: keyof typeof SIZES }) {
  const px = SIZES[size];
  return (
    <div
      className="relative flex items-center justify-center"
      style={{ width: px, height: px }}
      role="status"
      aria-label="جاري التحميل"
    >
      <div className="tree-loader-ring absolute inset-0 rounded-full" />
      <div className="tree-loader-breathe relative" style={{ width: px * 0.62, height: px * 0.62 }}>
        <Image src="/brand/tree.png" alt="" fill className="object-contain" />
      </div>
    </div>
  );
}
