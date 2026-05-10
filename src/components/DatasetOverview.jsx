import { useLanguage } from '../context/LanguageContext'
import './DatasetOverview.css'

const variables = [
  { name: 'Rainfall', unit: 'mm' },
  { name: 'Average temperature', unit: '°C' },
  { name: 'Humidity', unit: '%' },
  { name: 'Soil pH', unit: '—' },
  { name: 'Nitrogen (N)', unit: '%' },
  { name: 'Phosphorus (P)', unit: 'mg/kg' },
  { name: 'Potassium (K)', unit: 'mg/kg' },
  { name: 'Cultivated area', unit: 'ha' },
  { name: 'Agricultural yield (target)', unit: 't/ha' },
]

export default function DatasetOverview() {
  const { language } = useLanguage()

  const copy = {
    en: {
      title: 'Dataset variables',
      desc: 'Numerical features used to predict agricultural yield.',
      variable: 'Variable',
      unit: 'Unit',
      note: 'Main file used for ML:',
    },
    fr: {
      title: 'Variables du jeu de donnees',
      desc: 'Variables numeriques utilisees pour predire le rendement agricole.',
      variable: 'Variable',
      unit: 'Unite',
      note: 'Fichier principal utilise pour le ML :',
    },
    ar: {
      title: 'متغيرات البيانات',
      desc: 'المتغيرات الرقمية المستخدمة لتوقع المردودية الزراعية.',
      variable: 'المتغير',
      unit: 'الوحدة',
      note: 'الملف الرئيسي المستخدم في التعلم الالي:',
    },
  }

  const text = copy[language] || copy.en

  return (
    <section className="section section-alt" id="dataset">
      <div className="section-inner">
        <h2 className="section-title">{text.title}</h2>
        <p className="section-desc">{text.desc}</p>
        <div className="variables-table-wrap">
          <table className="variables-table">
            <thead>
              <tr>
                <th>{text.variable}</th>
                <th>{text.unit}</th>
              </tr>
            </thead>
            <tbody>
              {variables.map((v) => (
                <tr key={v.name}>
                  <td>{v.name}</td>
                  <td><code>{v.unit}</code></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <p className="dataset-note">
          {text.note} <code>data/dataset_ml_rendement_tunisie.csv</code>
        </p>
      </div>
    </section>
  )
}
