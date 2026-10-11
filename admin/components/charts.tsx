import { fmtDayShort, fmtDelta, fmtNum, pct } from '@/lib/format';
import { Dot, cx, type Tone } from './ui';
import { t, type AdminLocale } from '@/lib/i18n';

/**
 * Data display. Hand-rolled SVG rather than a charting library: two shapes are
 * needed, both are twenty lines, and neither justifies shipping a dependency
 * with its own theming system to fight.
 */

/* ── stat strip ───────────────────────────────────────────── */

export type Stat = {
  label: string;
  value: string;
  /** Secondary line: a share, a comparison, anything that gives the number scale. */
  foot?: string;
  /** Renders a signed change against the previous equivalent window. */
  delta?: { current: number; previous: number };
};

/**
 * A divided strip, not a grid of identical metric cards. Same information
 * without nine boxes competing for the same emphasis, and it stays readable when
 * every number is a single digit — which is exactly where a card grid looks
 * emptiest.
 */
export function StatStrip({ stats, locale = 'en' }: { stats: Stat[]; locale?: AdminLocale }) {
  return (
    <dl className="grid grid-cols-2 gap-px overflow-hidden rounded-lg border border-line bg-line sm:grid-cols-3 lg:grid-cols-6">
      {stats.map((stat, i) => {
        const delta = stat.delta ? fmtDelta(stat.delta.current, stat.delta.previous, locale) : null;
        return (
          <div key={stat.label} className="bg-surface px-3.5 py-3" style={{ ['--i' as string]: i }}>
            <dt className="text-xs text-ink-3">{stat.label}</dt>
            <dd className="mt-1 flex items-baseline gap-1.5">
              <span className="text-xl font-semibold tracking-tight text-ink">{stat.value}</span>
              {delta ? (
                <span
                  className={cx(
                    'text-xs font-medium',
                    delta.dir === 1 && 'text-ok',
                    delta.dir === -1 && 'text-danger',
                    delta.dir === 0 && 'text-ink-3',
                  )}
                  title={t(locale, 'Compared with the previous 7 days')}
                >
                  {delta.text}
                </span>
              ) : null}
            </dd>
            {stat.foot ? <p className="mt-0.5 text-xs text-ink-3">{stat.foot}</p> : null}
          </div>
        );
      })}
    </dl>
  );
}

/* ── activity chart ───────────────────────────────────────── */

export type Series = { key: string; label: string; tone: Tone; values: number[] };

const BAR_FILL: Record<Tone, string> = {
  neutral: 'fill-ink-3',
  ok: 'fill-ok',
  warn: 'fill-warn',
  danger: 'fill-danger',
  info: 'fill-info',
  accent: 'fill-accent',
};

/**
 * Grouped daily bars. Grouped rather than stacked: the question this answers is
 * "did contractors quote on the days homeowners posted", and a stacked bar hides
 * exactly that comparison inside a total nobody asked for.
 */
export function ActivityChart({ days, series, locale = 'en' }: { days: string[]; series: Series[]; locale?: AdminLocale }) {
  const n = days.length;
  const peak = Math.max(1, ...series.flatMap((s) => s.values));

  // Fixed geometry inside a scaled viewBox. The chart then fills its container
  // without a resize observer, and stays crisp because it is vector.
  const H = 132;
  const SLOT = 26;
  const GAP = 2.5;
  const W = n * SLOT;
  const barW = (SLOT - GAP * (series.length + 1)) / series.length;

  return (
    <div className="px-4 py-4">
      <div className="mb-3 flex flex-wrap items-center gap-x-4 gap-y-1.5">
        {series.map((s) => (
          <span key={s.key} className="flex items-center gap-1.5 text-xs text-ink-2">
            <Dot tone={s.tone} />
            {s.label}
            <span className="text-ink-3">{fmtNum(s.values.reduce((a, b) => a + b, 0), locale)}</span>
          </span>
        ))}
        <span className="ms-auto text-xs text-ink-3">{t(locale, 'Peak {count}/day', { count: fmtNum(peak, locale) })}</span>
      </div>

      <div className="scroll-x">
        <svg
          viewBox={`0 0 ${W} ${H + 18}`}
          preserveAspectRatio="none"
          className="h-[9.25rem] w-full min-w-[34rem]"
          role="img"
          aria-label={t(locale, 'Daily {series} over {days} days. Peak {peak} per day.', {
            series: series.map((s) => s.label).join(locale === 'ar' ? '، ' : ', '),
            days: fmtNum(n, locale), peak: fmtNum(peak, locale),
          })}
        >
          {/* Two reference lines. More than that is chartjunk at this size. */}
          {[0.5, 1].map((f) => (
            <line
              key={f}
              x1={0}
              x2={W}
              y1={H - H * f}
              y2={H - H * f}
              className="stroke-line"
              strokeWidth={1}
              vectorEffect="non-scaling-stroke"
            />
          ))}

          {days.map((day, d) => (
            <g key={day}>
              {(() => {
                const column = locale === 'ar' ? n - 1 - d : d;
                return series.map((s, si) => {
                  const value = s.values[d] ?? 0;
                  // Anything non-zero gets at least 2 units of height so a small
                  // value remains visible. Arabic dates advance from right to left.
                  const h = value === 0 ? 0 : Math.max(2, (value / peak) * H);
                  return (
                    <rect
                      key={s.key}
                      x={column * SLOT + GAP + si * (barW + GAP)}
                      y={H - h}
                      width={barW}
                      height={h}
                      rx={1}
                      className={BAR_FILL[s.tone]}
                    >
                      <title>{`${fmtDayShort(day, locale)} · ${s.label}: ${fmtNum(value, locale)}`}</title>
                    </rect>
                  );
                });
              })()}
              {d % 5 === 0 || d === n - 1 ? (
                <text
                  x={(locale === 'ar' ? n - 1 - d : d) * SLOT + SLOT / 2}
                  y={H + 13}
                  textAnchor="middle"
                  className="fill-ink-3 text-[9px]"
                >
                  {fmtDayShort(day, locale)}
                </text>
              ) : null}
            </g>
          ))}
        </svg>
      </div>
    </div>
  );
}

/* ── funnel ───────────────────────────────────────────────── */

export type FunnelStep = { label: string; value: number; note?: string };

/**
 * Conversion steps as horizontal bars, each labelled with its share of the step
 * above it. Share-of-previous rather than share-of-first: the biggest single drop
 * is the thing worth acting on, and share-of-first buries it.
 */
export function Funnel({ steps, locale = 'en' }: { steps: FunnelStep[]; locale?: AdminLocale }) {
  const first = steps[0]?.value ?? 0;

  return (
    <ol className="stagger flex flex-col gap-2.5 px-4 py-4">
      {steps.map((step, i) => {
        const previous = i === 0 ? step.value : (steps[i - 1]?.value ?? 0);
        const share = pct(step.value, previous);
        const width =
          first === 0 ? 0 : Math.max(step.value === 0 ? 0 : 1.5, (step.value / first) * 100);

        return (
          <li key={step.label} style={{ ['--i' as string]: i }}>
            <div className="flex items-baseline justify-between gap-3 text-sm">
              <span className="min-w-0 truncate text-ink-2">{step.label}</span>
              <span className="flex shrink-0 items-baseline gap-2">
                <span className="font-medium text-ink">{fmtNum(step.value, locale)}</span>
                {i > 0 ? (
                  <span
                    className={cx('text-xs', share < 40 ? 'text-warn' : 'text-ink-3')}
                    title={t(locale, 'Share of the previous step')}
                  >
                    {fmtNum(share, locale)}%
                  </span>
                ) : null}
              </span>
            </div>
            <div className="mt-1 h-1.5 overflow-hidden rounded-full bg-panel">
              <div
                className="h-full rounded-full bg-accent transition-[width] duration-200 ease-[var(--ease-out-quart)]"
                style={{ width: `${width}%` }}
              />
            </div>
            {step.note ? <p className="mt-1 text-xs text-ink-3">{step.note}</p> : null}
          </li>
        );
      })}
    </ol>
  );
}
