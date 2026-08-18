# The wholesale market pays for scale, not for flavour

A supply-side test of a premium honey concept, using ten years of USDA
production and price records.

**[View the dashboard →](https://lauwoes.github.io/honey-reserve-analysis/dashboard/)**

## The finding

US honey prices vary by nearly a factor of four between states, from about $1.90
a pound in North Dakota to $7.02 in Virginia. That looks like a market already
paying a premium for distinctive, low-volume, single-region honey.

It isn't. What the price tracks is production volume.

A regression of state average price on average yield per colony gives a
coefficient of −0.037 (p = 0.008), which reads as a flavour premium. Add log
production and the yield coefficient halves to −0.016 and stops being
distinguishable from zero (p = 0.118), while log production comes in at −0.71
(p < 0.001). A tenfold increase in a state's production is associated with
roughly $1.64 per pound less in price received.

Small states sell direct at close to retail. The Northern Plains sells by the
drum to packers. There is no varietal price signal in the wholesale data at all.

Production is also concentrated: five states account for 52 to 62 per cent of
national output every year, and only seven states ever appear in that top five.

## Where this came from

The concept came out of a Parsons branding brief: a premium Cheerios honey line
built on named varietals, small-batch sourcing and seasonal drops, positioned
above commodity honey "through nuance, character, and ingredient identity". The
strategy was sound as positioning and untested as economics.

I expected to find a category that under-prices distinctiveness. I found one
that prices scale and nothing else.

That doesn't kill the concept, but it changes the argument. "We are surfacing
value the category ignores" becomes "we are manufacturing value the category
does not price" — which is what Graza and Carbone do, both named in the original
deck, and which carries different risks and needs different proof.

## Running it

The repository ships with no data, so every figure is one you pulled yourself.

1. Get a free key at [quickstats.nass.usda.gov/api](https://quickstats.nass.usda.gov/api)
2. Open `notebooks/honey_analysis.ipynb` in
   [Google Colab](https://colab.research.google.com) (File → Upload notebook)
3. Add the key as a Colab secret named `NASS_API_KEY`, or let the notebook prompt for it
4. Run all cells

The notebook writes `honey.db`, `honey_panel.csv` and `state_summary.csv`.

## Layout

| Path | What it is |
| --- | --- |
| `notebooks/honey_analysis.ipynb` | The analysis, runnable end to end |
| `notebooks/honey_analysis.py` | Same content as a script, for readable diffs |
| `sql/queries.sql` | Window-function queries against the generated database |
| `dashboard/index.html` | Findings dashboard, no build step |

## Data handling

Three decisions in the cleaning are worth knowing, because each one changes the
numbers:

**Census and survey records are not mixed.** USDA's five-yearly Census of
Agriculture is a full count; the annual figures come from a sample survey. They
use different coverage and rounding, and mixing them makes Alabama appear to
gain 4,700 colonies in 2017 purely from a change of method. Census rows are
excluded.

**Years after 2023 are excluded.** Survey coverage drops from 380 records in
2023 to 42 in 2026. That is USDA's publication lag, not a collapse in honey
production, and leaving it in puts a cliff on every trend line.

**Price was recovered from two unit series.** USDA publishes price in dollars
per pound and in cents per pound, and which appears varies by state and year.
Converting the cents series recovered 123 of 213 missing values. The two agree
exactly across every overlapping record, so the fill is verified rather than
assumed, and the notebook asserts this rather than trusting it.

The 90 rows still missing price are also missing production, value and yield.
Those are state-years where USDA recorded hives but published no honey figures,
so they drop out cleanly.

## Limitations

**Price received is not retail price.** The channel explanation is inference
from the pattern, not something USDA reports.

**The regression uses state averages**, so it has 41 observations. Suggestive,
not decisive.

**Varietal composition is not in this data.** Reading California as almond and
citrus honey comes from general knowledge. Evidencing it needs another source.

**Hawaii yields 104 lb per colony** on a different production system, and the
models should be reported with and without it.

## Sources

USDA NASS Quick Stats, Honey survey series, 2015–2023. Public domain.
