import { useLanguage } from '../context/LanguageContext'
import './Pipeline.css'

const steps = [
  { num: 1, title: 'Collection', desc: 'Scraping / download from Agridata, INM, FAOSTAT, and Open-Meteo', done: true },
  { num: 2, title: 'Preprocessing', desc: 'Cleaning, normalization, and dataset merging', done: true },
  { num: 3, title: 'EDA', desc: 'Descriptive statistics and visualizations', done: false },
  { num: 4, title: 'ML', desc: 'Clustering (K-Means), PCA, and regression (Random Forest, linear regression)', done: false },
  { num: 5, title: 'Evaluation', desc: 'RMSE, MAE, and R²', done: false },
  { num: 6, title: 'Interpretation', desc: 'Feature importance and cluster analysis', done: false },
]

export default function Pipeline() {
  const { language } = useLanguage()

  const copy = {
    en: {
      title: 'Project pipeline',
      desc: 'Main stages of the agricultural yield prediction workflow.',
      done: 'Done',
    },
    fr: {
      title: 'Pipeline du projet',
      desc: 'Principales etapes du flux de prediction du rendement agricole.',
      done: 'Termine',
    },
    ar: {
      title: 'مسار المشروع',
      desc: 'المراحل الرئيسية لسير عمل توقع المردودية الزراعية.',
      done: 'مكتمل',
    },
  }

  const text = copy[language] || copy.en

  return (
    <section className="section" id="pipeline">
      <div className="section-inner">
        <h2 className="section-title">{text.title}</h2>
        <p className="section-desc">{text.desc}</p>
        <div className="pipeline-list">
          {steps.map((s) => (
            <div key={s.num} className={`pipeline-step ${s.done ? 'done' : ''}`}>
              <div className="step-num">{s.num}</div>
              <div className="step-content">
                <h3 className="step-title">{s.title}</h3>
                <p className="step-desc">{s.desc}</p>
              </div>
              {s.done && <span className="step-badge">{text.done}</span>}
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
