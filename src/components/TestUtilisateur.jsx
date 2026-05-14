import { useMemo, useState } from 'react'
import { useLanguage } from '../context/LanguageContext'
import './TestUtilisateur.css'

const API_BASE = import.meta.env.VITE_API_URL || ''

const sampleValues = {
  pluviometrie: '320',
  temperature: '21.4',
  humidite: '64',
  ph: '6.9',
  azote: '0.18',
  phosphore: '42',
  potassium: '165',
  surface: '8.5',
}

const modelOptions = ['random_forest', 'gradient_boosting', 'stacking']

export default function TestUtilisateur() {
  const { language } = useLanguage()
  const [values, setValues] = useState({
    pluviometrie: '',
    temperature: '',
    humidite: '',
    ph: '',
    azote: '',
    phosphore: '',
    potassium: '',
    surface: '',
  })
  const [prediction, setPrediction] = useState(null)
  const [selectedModel, setSelectedModel] = useState('gradient_boosting')
  const [predictedModel, setPredictedModel] = useState(null)
  const [predictionQuality, setPredictionQuality] = useState(null)
  const [anomalyDetected, setAnomalyDetected] = useState(null)
  const [anomalyReason, setAnomalyReason] = useState(null)
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(false)

  const copy = {
    en: {
      title: 'Yield prediction test',
      desc: 'Simulate your parcel with climate and soil values, then generate an instant yield forecast.',
      helper: 'Use realistic values from your field data and weather records for better reliability.',
      statsLabel: 'Form completion',
      sample: 'Use sample values',
      reset: 'Reset form',
      climate: 'Climate indicators',
      soil: 'Soil chemistry',
      production: 'Production context',
      rainfall: 'Rainfall (mm)',
      temperature: 'Average temperature (deg C)',
      humidity: 'Humidity (%)',
      ph: 'Soil pH',
      n: 'Nitrogen N (%)',
      p: 'Phosphorus P (mg/kg)',
      k: 'Potassium K (mg/kg)',
      area: 'Cultivated area (ha)',
      modelLabel: 'Prediction model',
        modelRandomForest: 'Random Forest',
        modelGradientBoosting: 'Gradient Boosting',
        modelStacking: 'Stacking Ensemble',

      calculate: 'Calculating...',
      predict: 'Predict yield',
      invalid: 'Please fill in all fields with valid numeric values.',
      errorLabel: 'Error',
        resultLabel: 'Predicted yield',
        resultNote: 'Prediction returned by FastAPI endpoint.',
        resultModel: 'Model used',
        qualityLabel: 'Yield quality',
        qualityLow: 'Low',
        qualityModerate: 'Moderate',
        qualityGood: 'Good',
        qualityExcellent: 'Excellent',
        anomalyLabel: 'Anomaly',
        anomalyDetected: 'Detected',
        anomalyNotDetected: 'Not detected',
        anomalyReasonLabel: 'Reason',

      cards: [
        { title: 'Fast simulation', note: 'Get an estimate in seconds' },
        { title: 'Field relevant', note: 'Climate + soil + area context' },
        { title: 'Decision support', note: 'Turn prediction into action' },
      ],
    },
    fr: {
      title: 'Test de prediction du rendement',
      desc: 'Simulez votre parcelle avec des valeurs climatiques et du sol, puis obtenez une prevision instantanee.',
      helper: 'Utilisez des valeurs realistes issues de vos observations terrain et donnees meteo.',
      statsLabel: 'Progression du formulaire',
      sample: 'Utiliser des valeurs exemple',
      reset: 'Reinitialiser',
      climate: 'Indicateurs climatiques',
      soil: 'Chimie du sol',
      production: 'Contexte de production',
      rainfall: 'Pluviometrie (mm)',
      temperature: 'Temperature moyenne (deg C)',
      humidity: 'Humidite (%)',
      ph: 'pH du sol',
      n: 'Azote N (%)',
      p: 'Phosphore P (mg/kg)',
      k: 'Potassium K (mg/kg)',
      area: 'Surface cultivee (ha)',
      modelLabel: 'Modele de prediction',
        modelRandomForest: 'Random Forest',
        modelGradientBoosting: 'Gradient Boosting',
        modelStacking: 'Stacking Ensemble',

      calculate: 'Calcul en cours...',
      predict: 'Predire le rendement',
      invalid: 'Veuillez renseigner tous les champs avec des valeurs numeriques valides.',
      errorLabel: 'Erreur',
        resultLabel: 'Rendement predit',
        resultNote: "Resultat retourne par l'endpoint FastAPI.",
        resultModel: 'Modele utilise',
        qualityLabel: 'Qualite du rendement',
        qualityLow: 'Faible',
        qualityModerate: 'Moyenne',
        qualityGood: 'Bonne',
        qualityExcellent: 'Excellente',
        anomalyLabel: 'Anomalie',
        anomalyDetected: 'Detectee',
        anomalyNotDetected: 'Non detectee',
        anomalyReasonLabel: 'Raison',

      cards: [
        { title: 'Simulation rapide', note: 'Une estimation en quelques secondes' },
        { title: 'Pertinent terrain', note: 'Climat + sol + surface' },
        { title: 'Aide a la decision', note: 'Passez de la prediction a l action' },
      ],
    },
    ar: {
      title: 'اختبار توقع المردودية',
      desc: 'حاكي قطعة الأرض بقيم المناخ والتربة ثم احصل على توقع فوري للمردودية.',
      helper: 'استعمل قيما واقعية من معطيات الحقل وسجلات الطقس لتحسين الدقة.',
      statsLabel: 'تقدم تعبئة النموذج',
      sample: 'استخدام قيم تجريبية',
      reset: 'اعادة الضبط',
      climate: 'مؤشرات المناخ',
      soil: 'كيمياء التربة',
      production: 'سياق الانتاج',
      rainfall: 'التساقطات (مم)',
      temperature: 'متوسط الحرارة (درجة مئوية)',
      humidity: 'الرطوبة (%)',
      ph: 'حموضة التربة',
      n: 'النتروجين N (%)',
      p: 'الفوسفور P (mg/kg)',
      k: 'البوتاسيوم K (mg/kg)',
      area: 'المساحة المزروعة (هكتار)',
      modelLabel: 'نموذج التوقع',
        modelRandomForest: 'Random Forest',
        modelGradientBoosting: 'Gradient Boosting',
        modelStacking: 'Stacking Ensemble',

      calculate: 'جاري الحساب...',
      predict: 'توقع المردودية',
      invalid: 'يرجى ملء كل الحقول بقيم رقمية صالحة.',
      errorLabel: 'خطأ',
        resultLabel: 'المردودية المتوقعة',
        resultNote: 'النتيجة راجعة من واجهة FastAPI.',
        resultModel: 'النموذج المستخدم',
        qualityLabel: 'جودة المردودية',
        qualityLow: 'ضعيفة',
        qualityModerate: 'متوسطة',
        qualityGood: 'جيدة',
        qualityExcellent: 'ممتازة',
        anomalyLabel: 'الشذوذ',
        anomalyDetected: 'تم اكتشافه',
        anomalyNotDetected: 'غير موجود',
        anomalyReasonLabel: 'السبب',

      cards: [
        { title: 'محاكاة سريعة', note: 'نتيجة تقديرية في ثوان' },
        { title: 'ملائم للميدان', note: 'مناخ + تربة + مساحة' },
        { title: 'دعم القرار', note: 'حول التوقع الى اجراء عملي' },
      ],
    },
  }

  const text = copy[language] || copy.en

  const modelLabels = {
    random_forest: text.modelRandomForest,
    gradient_boosting: text.modelGradientBoosting,
    stacking: text.modelStacking,
  }

  const qualityLabels = {
    low: text.qualityLow,
    moderate: text.qualityModerate,
    good: text.qualityGood,
    excellent: text.qualityExcellent,
  }

  const completion = useMemo(() => {
    const total = Object.keys(values).length
    const completed = Object.values(values).filter((value) => value !== '').length
    return Math.round((completed / total) * 100)
  }, [values])

  const handleChange = (e) => {
    const { name, value } = e.target
    setValues((prev) => ({ ...prev, [name]: value }))
    setPrediction(null)
    setPredictedModel(null)
    setPredictionQuality(null)
    setAnomalyDetected(null)
    setAnomalyReason(null)
    setError(null)
  }

  const fillSample = () => {
    setValues(sampleValues)
    setPrediction(null)
    setPredictedModel(null)
    setPredictionQuality(null)
    setAnomalyDetected(null)
    setAnomalyReason(null)
    setError(null)
  }

  const resetForm = () => {
    setValues({
      pluviometrie: '',
      temperature: '',
      humidite: '',
      ph: '',
      azote: '',
      phosphore: '',
      potassium: '',
      surface: '',
    })
    setPrediction(null)
    setPredictedModel(null)
    setPredictionQuality(null)
    setAnomalyDetected(null)
    setAnomalyReason(null)
    setError(null)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError(null)
    setPrediction(null)
    setPredictedModel(null)
    setPredictionQuality(null)
    setAnomalyDetected(null)
    setAnomalyReason(null)

    const features = {
      pluviometrie: Number(values.pluviometrie),
      temperature: Number(values.temperature),
      humidite: Number(values.humidite),
      ph: Number(values.ph),
      azote: Number(values.azote),
      phosphore: Number(values.phosphore),
      potassium: Number(values.potassium),
      surface: Number(values.surface),
    }

    const hasEmpty = Object.values(features).some((v) => Number.isNaN(v))
    if (hasEmpty) {
      setError(text.invalid)
      return
    }

    const payload = {
      model: selectedModel,
      features,
    }

    setLoading(true)
    try {
      const res = await fetch(`${API_BASE}/api/predict`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      })

      if (!res.ok) {
        const errData = await res.json().catch(() => ({}))
        const detail = errData.detail
        const msg = Array.isArray(detail)
          ? detail.map((d) => d.msg || d.loc?.join('.')).join(', ')
          : typeof detail === 'string'
            ? detail
            : `Error ${res.status}`
        throw new Error(msg)
      }

      const data = await res.json()
      setPrediction(data.rendement_t_ha)
      setPredictedModel(data.model)
      setPredictionQuality(data.rendement_quality || null)
      setAnomalyDetected(typeof data.anomaly_detected === 'boolean' ? data.anomaly_detected : null)
      setAnomalyReason(data.anomaly_reason || null)
    } catch (err) {
      setError(err.message || 'API call failed.')
      setPrediction(null)
      setPredictedModel(null)
      setPredictionQuality(null)
      setAnomalyDetected(null)
      setAnomalyReason(null)
    } finally {
      setLoading(false)
    }
  }

  return (
    <section className="section section-test" id="test">
      <div className="section-inner">
        <div className="test-hero-grid">
          <div>
            <h2 className="section-title">{text.title}</h2>
            <p className="section-desc">{text.desc}</p>
            <p className="test-helper">{text.helper}</p>
            <div className="test-toolbar">
              <div className="test-progress">
                <div className="test-progress-row">
                  <span>{text.statsLabel}</span>
                  <strong>{completion}%</strong>
                </div>
                <div className="test-progress-track" aria-hidden="true">
                  <span className="test-progress-fill" style={{ width: `${completion}%` }} />
                </div>
              </div>
              <div className="test-toolbar-actions">
                <button type="button" className="btn-secondary" onClick={fillSample}>{text.sample}</button>
                <button type="button" className="btn-ghost" onClick={resetForm}>{text.reset}</button>
              </div>
            </div>
          </div>
          <div className="test-kpi-grid">
            {text.cards.map((card) => (
              <div key={card.title} className="test-kpi-card">
                <p className="test-kpi-title">{card.title}</p>
                <p className="test-kpi-note">{card.note}</p>
              </div>
            ))}
          </div>
        </div>

          <form className="test-form" onSubmit={handleSubmit}>
            <p className="test-group-title">{text.modelLabel}</p>
            <div className="form-row">
                <label>
                  {text.modelLabel}
                  <select name="model" value={selectedModel} onChange={(e) => {
                    setSelectedModel(e.target.value)
                    setPrediction(null)
                    setPredictedModel(null)
                    setPredictionQuality(null)
                    setAnomalyDetected(null)
                    setAnomalyReason(null)
                    setError(null)
                  }}>

                  {modelOptions.map((model) => (
                    <option key={model} value={model}>
                      {modelLabels[model]}
                    </option>
                  ))}
                </select>
              </label>
            </div>

            <p className="test-group-title">{text.climate}</p>

          <div className="form-row">
            <label>
              {text.rainfall}
              <input type="number" name="pluviometrie" value={values.pluviometrie} onChange={handleChange} placeholder="e.g. 350" step="0.1" min="0" />
            </label>
            <label>
              {text.temperature}
              <input type="number" name="temperature" value={values.temperature} onChange={handleChange} placeholder="e.g. 18.5" step="0.1" />
            </label>
            <label>
              {text.humidity}
              <input type="number" name="humidite" value={values.humidite} onChange={handleChange} placeholder="e.g. 65" min="0" max="100" step="0.1" />
            </label>
          </div>

          <p className="test-group-title">{text.soil}</p>
          <div className="form-row">
            <label>
              {text.ph}
              <input type="number" name="ph" value={values.ph} onChange={handleChange} placeholder="e.g. 7.2" step="0.1" min="0" max="14" />
            </label>
            <label>
              {text.n}
              <input type="number" name="azote" value={values.azote} onChange={handleChange} placeholder="e.g. 0.15" step="0.01" min="0" />
            </label>
            <label>
              {text.p}
              <input type="number" name="phosphore" value={values.phosphore} onChange={handleChange} placeholder="e.g. 45" min="0" />
            </label>
            <label>
              {text.k}
              <input type="number" name="potassium" value={values.potassium} onChange={handleChange} placeholder="e.g. 180" min="0" />
            </label>
          </div>

          <p className="test-group-title">{text.production}</p>
          <div className="form-row">
            <label>
              {text.area}
              <input type="number" name="surface" value={values.surface} onChange={handleChange} placeholder="e.g. 10" step="0.1" min="0" />
            </label>
          </div>

          <button type="submit" className="btn-predict" disabled={loading}>
            {loading ? text.calculate : text.predict}
          </button>
        </form>

        {error && (
          <div className="prediction-result prediction-error">
            <span className="prediction-label">{text.errorLabel}</span>
            <p className="prediction-note">{error}</p>
          </div>
        )}

            {prediction !== null && !error && (
              <div className="prediction-result">
                <span className="prediction-label">{text.resultLabel}</span>
                <span className="prediction-value">{prediction.toFixed(2)} t/ha</span>
                <p className="prediction-note">{text.resultNote}</p>
                {predictedModel && (
                  <p className="prediction-model">
                    {text.resultModel}: <strong>{modelLabels[predictedModel] || predictedModel}</strong>
                  </p>
                )}
                {predictionQuality && (
                  <p className="prediction-model">
                    {text.qualityLabel}: <strong>{qualityLabels[predictionQuality] || predictionQuality}</strong>
                  </p>
                )}
                {anomalyDetected !== null && (
                  <p className={`prediction-model ${anomalyDetected ? 'prediction-anomaly' : 'prediction-normal'}`}>
                    {text.anomalyLabel}: <strong>{anomalyDetected ? text.anomalyDetected : text.anomalyNotDetected}</strong>
                  </p>
                )}
                {anomalyDetected && anomalyReason && (
                  <p className="prediction-note">
                    {text.anomalyReasonLabel}: {anomalyReason}
                  </p>
                )}
              </div>
            )}


      </div>
    </section>
  )
}
