import { Card } from "@/components/ui/Card";
import { BarBreakdown } from "@/components/charts/BarBreakdown";
import { CrossTab } from "@/components/charts/CrossTab";
import { Donut } from "@/components/charts/Donut";
import { formatNumber } from "@/lib/format";
import {
  getCountryDistribution,
  getTopSituations,
  getTopEmotionalStates,
  getTopPatterns,
  getProblemByAgeGroup,
  getSuccessRateBySituation,
  getCountryByProblem,
  getTopObjectives,
  getContinuityDistribution,
  getClarityFromFirstMessage,
  getAvgNightsToFirstCalm,
} from "@/lib/queries/insights";

export const dynamic = "force-dynamic";
export const revalidate = 0;

export default async function InsightsPage() {
  const [
    countries,
    situations,
    emotions,
    patterns,
    ageGroup,
    successRate,
    countryByProblem,
    objectives,
    continuity,
    clarity,
    avgCalm,
  ] = await Promise.all([
    getCountryDistribution(),
    getTopSituations(),
    getTopEmotionalStates(),
    getTopPatterns(),
    getProblemByAgeGroup(),
    getSuccessRateBySituation(),
    getCountryByProblem(),
    getTopObjectives(),
    getContinuityDistribution(),
    getClarityFromFirstMessage(),
    getAvgNightsToFirstCalm(),
  ]);

  const clarityTotal = clarity.clear + clarity.needsFollowUp;

  return (
    <div className="flex flex-col gap-6">
      <p className="max-w-3xl text-sm text-[color:var(--text-muted)]">
        كل الأرقام هنا مجمّعة عبر جميع العائلات — لا يوجد بهذه الصفحة أي جدول يربط رقماً باسم أو معرّف عميل محدد.
      </p>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card title="توزيع البلدان" subtitle="عدد العائلات لكل بلد">
          <BarBreakdown items={countries} />
        </Card>
        <Card title="أكبر مشكل سلوكي متكرر" subtitle="من مواقف الأطفال المسجَّلة">
          <BarBreakdown items={situations} />
        </Card>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card title="أكبر شعور عند الوالد" subtitle="من ذاكرة القلب — عبارات مجمّعة، بلا أسماء">
          {emotions.length === 0 ? (
            <p className="text-sm text-[color:var(--text-muted)]">لا بيانات كافية بعد.</p>
          ) : (
            <BarBreakdown items={emotions} />
          )}
        </Card>
        <Card title="أكثر الأنماط تكراراً" subtitle="عبر كل العائلات">
          {patterns.length === 0 ? (
            <p className="text-sm text-[color:var(--text-muted)]">لا بيانات كافية بعد.</p>
          ) : (
            <BarBreakdown items={patterns} />
          )}
        </Card>
      </div>

      <Card title="المشكل السلوكي حسب الفئة العمرية للطفل">
        {ageGroup.rows.length === 0 ? (
          <p className="text-sm text-[color:var(--text-muted)]">لا بيانات كافية بعد.</p>
        ) : (
          <CrossTab
            rowLabels={ageGroup.rows}
            colLabels={ageGroup.cols}
            cell={(r, c) => ageGroup.data.get(r)?.get(c) ?? 0}
          />
        )}
      </Card>

      <Card title="نسبة نجاح آدم بكل نوع موقف" subtitle="نسبة الخطوات التي أثمرت (step_status = done)">
        {successRate.length === 0 ? (
          <p className="text-sm text-[color:var(--text-muted)]">لا بيانات كافية بعد.</p>
        ) : (
          <BarBreakdown
            items={successRate.map((s) => ({
              label: s.label,
              value: Math.round(s.rate * 100),
              hint: `${formatNumber(s.done)} من ${formatNumber(s.total)} خطوة`,
            }))}
          />
        )}
      </Card>

      <Card title="جدول متقاطع: البلد × نوع المشكلة">
        {countryByProblem.rows.length === 0 ? (
          <p className="text-sm text-[color:var(--text-muted)]">لا بيانات كافية بعد — لا رحلات مدفوعة مسجَّلة بعد.</p>
        ) : (
          <CrossTab
            rowLabels={countryByProblem.rows}
            colLabels={countryByProblem.cols}
            cell={(r, c) => countryByProblem.data.get(r)?.get(c) ?? 0}
          />
        )}
      </Card>

      <Card title="أكثر الأهداف طلباً" subtitle="أكثر عبارات الهدف تكراراً في الرحلات">
        {objectives.length === 0 ? (
          <p className="text-sm text-[color:var(--text-muted)]">لا بيانات كافية بعد.</p>
        ) : (
          <BarBreakdown items={objectives} />
        )}
      </Card>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card title="توزيع مدى الاستمرارية" subtitle="كم عائلة وصلت لكل محطة تتابع">
          <BarBreakdown items={continuity} />
        </Card>

        <Card title="وضوح السبب من أول رسالة" subtitle="مقياس تقريبي: evidence_count = 1 يعني اتضح من أول رصد">
          {clarityTotal === 0 ? (
            <p className="text-sm text-[color:var(--text-muted)]">لا بيانات كافية بعد.</p>
          ) : (
            <Donut
              data={[
                { name: "اتّضح من أول رسالة", value: clarity.clear },
                { name: "احتاج أسئلة إضافية", value: clarity.needsFollowUp },
              ]}
              centerLabel="موقف"
            />
          )}
        </Card>
      </div>

      <Card title="متوسط الليالي حتى أول نتيجة هادئة">
        {avgCalm.sampleSize === 0 ? (
          <p className="text-sm text-[color:var(--text-muted)]">لا توجد عائلة وصلت لليلة هادئة بعد.</p>
        ) : (
          <div className="flex items-baseline gap-3">
            <span className="tabular text-3xl font-bold text-[color:var(--primary)]">
              {avgCalm.avgNights.toLocaleString("ar", { maximumFractionDigits: 1 })}
            </span>
            <span className="text-sm text-[color:var(--text-muted)]">
              ليلة بالمتوسط — من {formatNumber(avgCalm.sampleSize)} عائلة حققت ليلة هادئة واحدة على الأقل
            </span>
          </div>
        )}
      </Card>
    </div>
  );
}
