import Layout from '../components/Layout'
import { useLanguage } from '../context/LanguageContext'
import {
  LineChart, Line,
  BarChart, Bar,
  RadarChart, Radar, PolarGrid, PolarAngleAxis,
  AreaChart, Area,
  XAxis, YAxis, CartesianGrid, Tooltip, Legend,
  ResponsiveContainer,
} from 'recharts'
import './DashboardPage.css'

const yieldTrend = [
  { year: '2015', rendement: 1.8 },
  { year: '2016', rendement: 2.1 },
  { year: '2017', rendement: 1.5 },
  { year: '2018', rendement: 2.4 },
  { year: '2019', rendement: 2.9 },
  { year: '2020', rendement: 2.2 },
  { year: '2021', rendement: 3.1 },
  { year: '2022', rendement: 2.7 },
  { year: '2023', rendement: 3.4 },
]

const yieldByRegion = [
  { region: 'Tunis',    rendement: 3.2 },
  { region: 'Sfax',     rendement: 2.1 },
  { region: 'Sousse',   rendement: 2.8 },
  { region: 'Siliana',  rendement: 3.6 },
  { region: 'Béja',     rendement: 4.1 },
  { region: 'Jendouba', rendement: 3.8 },
  { region: 'Zaghouan', rendement: 2.5 },
]

const soilRadar = [
  { metric: 'Azote (N)',    value: 72 },
  { metric: 'Phosphore (P)', value: 58 },
  { metric: 'Potassium (K)', value: 85 },
  { metric: 'pH',           value: 68 },
  { metric: 'Humidité',     value: 61 },
  { metric: 'Matière org.', value: 45 },
]

const rainfall = [
  { month: 'Jan', pluie: 52 },
  { month: 'Fév', pluie: 44 },
  { month: 'Mar', pluie: 38 },
  { month: 'Avr', pluie: 29 },
  { month: 'Mai', pluie: 18 },
  { month: 'Jun', pluie: 6  },
  { month: 'Jul', pluie: 2  },
  { month: 'Aoû', pluie: 5  },
  { month: 'Sep', pluie: 24 },
  { month: 'Oct', pluie: 41 },
  { month: 'Nov', pluie: 55 },
  { month: 'Déc', pluie: 60 },
]

const copy = {
  en: {
    title: 'Dashboard',
    subtitle: 'Agricultural indicators for Tunisia — climate, soil & yield',
    yieldTrend: 'Yield Trend (t/ha) 2015–2023',
    yieldRegion: 'Average Yield by Region (t/ha)',
    soilTitle: 'Soil Quality Index',
    rainfallTitle: 'Monthly Rainfall (mm)',
    tHa: 't/ha',
    mm: 'mm',
    score: 'Score /100',
  },
  fr: {
    title: 'Tableau de bord',
    subtitle: 'Indicateurs agricoles pour la Tunisie — climat, sol et rendement',
    yieldTrend: 'Tendance du rendement (t/ha) 2015–2023',
    yieldRegion: 'Rendement moyen par région (t/ha)',
    soilTitle: 'Indice de qualité des sols',
    rainfallTitle: 'Pluviométrie mensuelle (mm)',
    tHa: 't/ha',
    mm: 'mm',
    score: 'Score /100',
  },
  ar: {
    title: 'لوحة القيادة',
    subtitle: 'المؤشرات الزراعية لتونس — المناخ والتربة والمردودية',
    yieldTrend: 'تطور المردودية (ط/هك) 2015–2023',
    yieldRegion: 'متوسط المردودية حسب الجهة (ط/هك)',
    soilTitle: 'مؤشر جودة التربة',
    rainfallTitle: 'التساقطات الشهرية (مم)',
    tHa: 'ط/هك',
    mm: 'مم',
    score: 'نقطة /100',
  },
}

export default function DashboardPage() {
  const { language } = useLanguage()
  const t = copy[language] || copy.en

  return (
    <Layout>
      <section className="dash-hero">
        <h1 className="dash-title">{t.title}</h1>
        <p className="dash-subtitle">{t.subtitle}</p>
      </section>

      <div className="dash-grid">

        {/* Line chart — yield over years */}
        <div className="dash-card">
          <h2 className="dash-card-title">{t.yieldTrend}</h2>
          <ResponsiveContainer width="100%" height={260}>
            <LineChart data={yieldTrend} margin={{ top: 10, right: 20, left: 0, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(88,136,105,0.15)" />
              <XAxis dataKey="year" tick={{ fontSize: 12 }} />
              <YAxis unit=" t/ha" tick={{ fontSize: 12 }} domain={[0, 5]} />
              <Tooltip formatter={(v) => [`${v} ${t.tHa}`, t.yieldTrend]} />
              <Line
                type="monotone"
                dataKey="rendement"
                stroke="#2f935e"
                strokeWidth={2.5}
                dot={{ r: 4, fill: '#2f935e' }}
                activeDot={{ r: 6 }}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* Bar chart — yield by region */}
        <div className="dash-card">
          <h2 className="dash-card-title">{t.yieldRegion}</h2>
          <ResponsiveContainer width="100%" height={260}>
            <BarChart data={yieldByRegion} margin={{ top: 10, right: 20, left: 0, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(88,136,105,0.15)" />
              <XAxis dataKey="region" tick={{ fontSize: 11 }} />
              <YAxis unit=" t/ha" tick={{ fontSize: 12 }} domain={[0, 5]} />
              <Tooltip formatter={(v) => [`${v} ${t.tHa}`, 'Rendement']} />
              <Bar dataKey="rendement" fill="#4eb87a" radius={[6, 6, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Radar chart — soil quality */}
        <div className="dash-card">
          <h2 className="dash-card-title">{t.soilTitle}</h2>
          <ResponsiveContainer width="100%" height={260}>
            <RadarChart data={soilRadar} margin={{ top: 10, right: 30, left: 30, bottom: 10 }}>
              <PolarGrid stroke="rgba(88,136,105,0.2)" />
              <PolarAngleAxis dataKey="metric" tick={{ fontSize: 11, fill: '#3d6b4f' }} />
              <Radar
                name={t.score}
                dataKey="value"
                stroke="#2f935e"
                fill="#4eb87a"
                fillOpacity={0.35}
                strokeWidth={2}
              />
              <Tooltip formatter={(v) => [`${v}/100`, t.score]} />
            </RadarChart>
          </ResponsiveContainer>
        </div>

        {/* Area chart — monthly rainfall */}
        <div className="dash-card">
          <h2 className="dash-card-title">{t.rainfallTitle}</h2>
          <ResponsiveContainer width="100%" height={260}>
            <AreaChart data={rainfall} margin={{ top: 10, right: 20, left: 0, bottom: 0 }}>
              <defs>
                <linearGradient id="rainGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%"  stopColor="#4eb87a" stopOpacity={0.35} />
                  <stop offset="95%" stopColor="#4eb87a" stopOpacity={0.03} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(88,136,105,0.15)" />
              <XAxis dataKey="month" tick={{ fontSize: 12 }} />
              <YAxis unit=" mm" tick={{ fontSize: 12 }} />
              <Tooltip formatter={(v) => [`${v} ${t.mm}`, 'Pluviométrie']} />
              <Area
                type="monotone"
                dataKey="pluie"
                stroke="#2f935e"
                strokeWidth={2.5}
                fill="url(#rainGrad)"
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>

      </div>
    </Layout>
  )
}
