import { Link } from 'react-router-dom'
import { useLanguage } from '../context/LanguageContext'
import './Footer.css'

export default function Footer() {
  const { t } = useLanguage()
  const currentYear = new Date().getFullYear()

  return (
    <footer className="footer">
      <div className="footer-inner">
          <div className="footer-top">
            <div className="footer-brand-block">
              <div className="footer-brand">
                <img src="/logo.png" alt="VigorTerra" className="footer-logo" />
                <div>
                  <p className="footer-name">VigorTerra</p>
                  <p className="footer-tag">{t('footer.tag', 'Smart Agriculture Platform')}</p>
                </div>
              </div>
              <p className="footer-text">
                {t('footer.desc', 'Data-driven crop yield prediction powered by trusted climate and soil data.')}
              </p>
            </div>

            <div className="footer-links-grid">
              <div className="footer-col">
                <p className="footer-col-title">{t('footer.platform', 'Platform')}</p>
                <Link to="/" className="footer-link">{t('nav.home', 'Home')}</Link>
                <Link to="/profile" className="footer-link">{t('nav.profile', 'Profile')}</Link>
                <Link to="/test" className="footer-link">{t('footer.yieldTest', 'Yield Test')}</Link>
              </div>

              <div className="footer-col">
                <p className="footer-col-title">{t('footer.resources', 'Resources')}</p>
                <Link to="/sources" className="footer-link">{t('footer.dataSources', 'Data Sources')}</Link>
                <Link to="/dataset" className="footer-link">{t('nav.dataset', 'Dataset')}</Link>
                <Link to="/pipeline" className="footer-link">{t('nav.pipeline', 'Pipeline')}</Link>
              </div>

              <div className="footer-col">
                <p className="footer-col-title">{t('footer.partners', 'Data Partners')}</p>
                <p className="footer-meta">FAOSTAT</p>
                <p className="footer-meta">Open-Meteo</p>
                <p className="footer-meta">Agridata & INM</p>
              </div>
            </div>
          </div>

          <div className="footer-bottom">
            <p className="footer-copy">{currentYear} VigorTerra. {t('footer.copy', 'All rights reserved.')}</p>
            <p className="footer-footnote">{t('footer.note', 'Built for smart and sustainable agriculture in Tunisia.')}</p>
          </div>
      </div>
    </footer>
  )
}
