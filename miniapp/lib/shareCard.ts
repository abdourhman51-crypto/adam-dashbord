const CARD_W = 1080;
const CARD_H = 1350;

function loadImage(src: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const img = new window.Image();
    img.onload = () => resolve(img);
    img.onerror = reject;
    img.src = src;
  });
}

export async function drawAchievementCard(
  canvas: HTMLCanvasElement,
  { childName, streak }: { childName: string; streak: number }
) {
  canvas.width = CARD_W;
  canvas.height = CARD_H;
  const ctx = canvas.getContext("2d");
  if (!ctx) return;

  const gradient = ctx.createLinearGradient(0, 0, 0, CARD_H);
  gradient.addColorStop(0, "#102017");
  gradient.addColorStop(0.55, "#0d1a12");
  gradient.addColorStop(1, "#081009");
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, CARD_W, CARD_H);

  try {
    const tree = await loadImage("/brand/tree.png");
    ctx.globalAlpha = 0.16;
    const w = CARD_W * 0.9;
    const h = w * (tree.height / tree.width);
    ctx.drawImage(tree, (CARD_W - w) / 2, 80, w, h);
    ctx.globalAlpha = 1;
  } catch {
    // زخرفة اختيارية — البطاقة تبقى صحيحة بدونها
  }

  ctx.strokeStyle = "rgba(227,178,60,0.45)";
  ctx.lineWidth = 6;
  ctx.strokeRect(24, 24, CARD_W - 48, CARD_H - 48);

  ctx.textAlign = "center";
  ctx.fillStyle = "#a3b0a4";
  ctx.font = "600 34px 'Noto Sans Arabic', sans-serif";
  ctx.fillText("آدم — رفيق التربية", CARD_W / 2, 170);

  ctx.fillStyle = "#e3b23c";
  ctx.font = "700 340px 'Noto Naskh Arabic', serif";
  ctx.fillText(String(streak), CARD_W / 2, 760);

  ctx.fillStyle = "#f1efe6";
  ctx.font = "600 56px 'Noto Sans Arabic', sans-serif";
  ctx.fillText("ليلة متتالية", CARD_W / 2, 850);

  ctx.fillStyle = "#d9d5c9";
  ctx.font = "500 40px 'Noto Sans Arabic', sans-serif";
  ctx.fillText(`مع ${childName}`, CARD_W / 2, 940);

  ctx.fillStyle = "#f0c96a";
  ctx.font = "600 34px 'Noto Sans Arabic', sans-serif";
  ctx.fillText("هذا أنتم.", CARD_W / 2, 1220);
}

export function canvasToBlob(canvas: HTMLCanvasElement): Promise<Blob | null> {
  return new Promise((resolve) => canvas.toBlob(resolve, "image/png", 0.95));
}

export async function shareOrDownload(blob: Blob, filename: string) {
  const file = new File([blob], filename, { type: "image/png" });

  const nav = navigator as Navigator & {
    canShare?: (data: { files: File[] }) => boolean;
    share?: (data: { files: File[]; title?: string; text?: string }) => Promise<void>;
  };

  if (nav.canShare?.({ files: [file] }) && nav.share) {
    try {
      await nav.share({ files: [file], title: "بطاقة إنجاز آدم" });
      return;
    } catch {
      // المستخدم ألغى المشاركة أو فشلت — نكمل بالتحميل كبديل
    }
  }

  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 5000);
}
