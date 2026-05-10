import { useLanguage } from '../context/LanguageContext'
import './DataSources.css'

const sourcesByLanguage = {
  en: [
    { name: 'Agridata Tunisia', url: 'https://www.agridata.tn', desc: 'Rainfall, production, and agricultural statistics', icon: '📊' },
    { name: 'INM (Tunisia Weather)', url: 'http://www.meteo.tn', desc: 'Temperature, rainfall, and climate observations', icon: '🌤️' },
    { name: 'FAOSTAT', url: 'https://www.fao.org/faostat', desc: 'Yield, production, and cultivated area indicators', icon: '🌾' },
    { name: 'Open-Meteo', url: 'https://open-meteo.com', desc: 'Temperature, precipitation, and humidity API data', icon: '🌦️' },
  ],
  fr: [
    { name: 'Agridata Tunisia', url: 'https://www.agridata.tn', desc: 'Pluviometrie, production et statistiques agricoles', icon: '📊' },
    { name: 'INM (Meteo Tunisie)', url: 'http://www.meteo.tn', desc: 'Temperature, pluies et observations climatiques', icon: '🌤️' },
    { name: 'FAOSTAT', url: 'https://www.fao.org/faostat', desc: 'Indicateurs de rendement, production et surface cultivee', icon: '🌾' },
    { name: 'Open-Meteo', url: 'https://open-meteo.com', desc: 'Donnees API sur temperature, precipitation et humidite', icon: '🌦️' },
  ],
  ar: [
    { name: 'Agridata Tunisia', url: 'https://www.agridata.tn', desc: 'معطيات التساقطات والانتاج والاحصائيات الفلاحية', icon: '📊' },
    { name: 'INM (طقس تونس)', url: 'http://www.meteo.tn', desc: 'درجات الحرارة والتساقطات والملاحظات المناخية', icon: '🌤️' },
    { name: 'FAOSTAT', url: 'https://www.fao.org/faostat', desc: 'مؤشرات المردودية والانتاج والمساحة المزروعة', icon: '🌾' },
    { name: 'Open-Meteo', url: 'https://open-meteo.com', desc: 'بيانات API حول الحرارة والامطار والرطوبة', icon: '🌦️' },
  ],
}

export default function DataSources() {
  const { language } = useLanguage()

  const copy = {
    en: {
      title: 'Data sources',
      desc: 'Datasets collected to power the agricultural yield prediction model.',
    },
    fr: {
      title: 'Sources de donnees',
      desc: 'Jeux de donnees collectes pour alimenter le modele de prediction du rendement agricole.',
    },
    ar: {
      title: 'مصادر البيانات',
      desc: 'تم جمع هذه البيانات لدعم نموذج توقع المردودية الزراعية.',
    },
  }

  const text = copy[language] || copy.en
  const sources = sourcesByLanguage[language] || sourcesByLanguage.en

  return (
    <section className="section" id="sources">
      <div className="section-inner">
        <h2 className="section-title">{text.title}</h2>
        <p className="section-desc">{text.desc}</p>
        <div className="sources-grid">
          {sources.map((s) => (
            <a
              key={s.name}
              href={s.url}
              target="_blank"
              rel="noopener noreferrer"
              className="source-card"
            >
              <span className="source-icon">{s.icon}</span>
              <h3 className="source-name">{s.name}</h3>
              <p className="source-desc">{s.desc}</p>
            </a>
          ))}
        </div>
      </div>
    </section>
  )
}
