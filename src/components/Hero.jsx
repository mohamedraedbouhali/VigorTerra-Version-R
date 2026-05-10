import './Hero.css'

export default function Hero() {
  return (
    <section className="hero">
      <div className="hero-inner">
        <h1 className="hero-title">
          Prédiction du rendement agricole
        </h1>
        <p className="hero-subtitle">
          À partir des conditions climatiques et des caractéristiques du sol en Tunisie
        </p>
        <p className="hero-desc">
          Interface de suivi du projet : collecte des données (FAOSTAT, Open-Meteo, Agridata, INM),
          prétraitement et modèle de Machine Learning pour anticiper le rendement (t/ha).
        </p>
        <div className="hero-badges">
          <span className="badge">Agriculture intelligente</span>
          <span className="badge">Machine Learning</span>
          <span className="badge">Tunisie</span>
        </div>
      </div>
    </section>
  )
}
